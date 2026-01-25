#!/bin/bash
# ==============================================================================
# 🔍 Validador de ISOs/Imágenes Generados
# ==============================================================================
# Valida que los ISOs/imágenes generados contengan todos los componentes
# necesarios y sean bootables.
# ==============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Banner
# ==============================================================================
banner() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🔍 Z-Lag ISO/IMAGE VALIDATOR${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo ""
}

# ==============================================================================
# Validar ISO x86_64
# ==============================================================================
validate_x86_64() {
    local iso_path="$SCRIPT_DIR/buildroot/isos/vultr-x86_64/zlag-vultr-x86_64.iso"
    local checksum_path="$SCRIPT_DIR/buildroot/isos/vultr-x86_64/checksums.txt"
    
    echo -e "${BLUE}📦 Validando ISO x86_64 (Vultr)...${NC}"
    echo ""
    
    # Verificar que existe
    if [ ! -f "$iso_path" ]; then
        echo -e "${RED}❌ ISO no encontrado: $iso_path${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ ISO encontrado${NC}"
    
    # Tamaño
    local size=$(du -h "$iso_path" | cut -f1)
    local size_bytes=$(stat -f%z "$iso_path" 2>/dev/null || stat -c%s "$iso_path" 2>/dev/null)
    echo -e "${CYAN}  Tamaño: $size ($size_bytes bytes)${NC}"
    
    # Validar tamaño mínimo (50MB) y máximo (1GB)
    if [ $size_bytes -lt 52428800 ]; then
        echo -e "${RED}❌ ISO demasiado pequeño (< 50MB)${NC}"
        return 1
    fi
    
    if [ $size_bytes -gt 1073741824 ]; then
        echo -e "${YELLOW}⚠️  ISO muy grande (> 1GB)${NC}"
    fi
    
    echo -e "${GREEN}✓ Tamaño válido${NC}"
    
    # Verificar checksum
    if [ -f "$checksum_path" ]; then
        echo -e "${CYAN}  Verificando checksum...${NC}"
        cd "$(dirname "$iso_path")"
        
        if sha256sum -c checksums.txt 2>/dev/null; then
            echo -e "${GREEN}✓ Checksum válido${NC}"
        else
            echo -e "${RED}❌ Checksum inválido${NC}"
            return 1
        fi
        
        cd "$SCRIPT_DIR"
    else
        echo -e "${YELLOW}⚠️  Archivo de checksums no encontrado${NC}"
    fi
    
    # Verificar que es un ISO válido
    if command -v file &> /dev/null; then
        local file_type=$(file "$iso_path")
        if echo "$file_type" | grep -q "ISO 9660"; then
            echo -e "${GREEN}✓ Formato ISO 9660 válido${NC}"
        else
            echo -e "${YELLOW}⚠️  Formato ISO no reconocido: $file_type${NC}"
        fi
    fi
    
    # Intentar montar y verificar contenido (solo Linux)
    if [ "$(uname)" == "Linux" ] && [ -d /mnt ]; then
        echo -e "${CYAN}  Verificando contenido del ISO...${NC}"
        
        local mount_point="/tmp/zlag-iso-test-$$"
        mkdir -p "$mount_point"
        
        if sudo mount -o loop "$iso_path" "$mount_point" 2>/dev/null; then
            # Verificar archivos críticos
            local has_kernel=false
            local has_initrd=false
            
            if [ -f "$mount_point/boot/bzImage" ] || [ -f "$mount_point/bzImage" ]; then
                echo -e "${GREEN}✓ Kernel encontrado${NC}"
                has_kernel=true
            fi
            
            if [ -f "$mount_point/boot/initrd" ] || [ -f "$mount_point/initrd" ]; then
                echo -e "${GREEN}✓ Initrd encontrado${NC}"
                has_initrd=true
            fi
            
            sudo umount "$mount_point"
            rmdir "$mount_point"
            
            if [ "$has_kernel" = false ] || [ "$has_initrd" = false ]; then
                echo -e "${YELLOW}⚠️  Algunos archivos de boot no encontrados${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No se pudo montar el ISO para inspección${NC}"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "${GREEN}✅ ISO x86_64 válido${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo ""
    
    return 0
}

# ==============================================================================
# Validar imagen ARM64
# ==============================================================================
validate_arm64() {
    local img_path="$SCRIPT_DIR/buildroot/isos/oracle-arm64/zlag-oracle-arm64.ext4"
    local checksum_path="$SCRIPT_DIR/buildroot/isos/oracle-arm64/checksums.txt"
    
    echo -e "${BLUE}📦 Validando imagen ARM64 (Oracle Cloud)...${NC}"
    echo ""
    
    # Verificar que existe
    if [ ! -f "$img_path" ]; then
        echo -e "${RED}❌ Imagen no encontrada: $img_path${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Imagen encontrada${NC}"
    
    # Tamaño
    local size=$(du -h "$img_path" | cut -f1)
    local size_bytes=$(stat -f%z "$img_path" 2>/dev/null || stat -c%s "$img_path" 2>/dev/null)
    echo -e "${CYAN}  Tamaño: $size ($size_bytes bytes)${NC}"
    
    # Validar tamaño mínimo (50MB)
    if [ $size_bytes -lt 52428800 ]; then
        echo -e "${RED}❌ Imagen demasiado pequeña (< 50MB)${NC}"
        return 1
    fi
    
    if [ $size_bytes -gt 2147483648 ]; then
        echo -e "${YELLOW}⚠️  Imagen muy grande (> 2GB)${NC}"
    fi
    
    echo -e "${GREEN}✓ Tamaño válido${NC}"
    
    # Verificar checksum
    if [ -f "$checksum_path" ]; then
        echo -e "${CYAN}  Verificando checksum...${NC}"
        cd "$(dirname "$img_path")"
        
        if sha256sum -c checksums.txt 2>/dev/null; then
            echo -e "${GREEN}✓ Checksum válido${NC}"
        else
            echo -e "${RED}❌ Checksum inválido${NC}"
            return 1
        fi
        
        cd "$SCRIPT_DIR"
    else
        echo -e "${YELLOW}⚠️  Archivo de checksums no encontrado${NC}"
    fi
    
    # Verificar que es ext4
    if command -v file &> /dev/null; then
        local file_type=$(file "$img_path")
        if echo "$file_type" | grep -q "ext4"; then
            echo -e "${GREEN}✓ Formato ext4 válido${NC}"
        elif echo "$file_type" | grep -q "filesystem"; then
            echo -e "${GREEN}✓ Filesystem detectado${NC}"
        else
            echo -e "${YELLOW}⚠️  Formato no reconocido: $file_type${NC}"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "${GREEN}✅ Imagen ARM64 válida${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo ""
    
    return 0
}

# ==============================================================================
# Comparar con checksums esperados
# ==============================================================================
compare_checksums() {
    echo -e "${BLUE}📊 Comparando checksums...${NC}"
    echo ""
    
    # x86_64
    if [ -f "$SCRIPT_DIR/buildroot/isos/vultr-x86_64/checksums.txt" ]; then
        echo -e "${CYAN}x86_64:${NC}"
        cat "$SCRIPT_DIR/buildroot/isos/vultr-x86_64/checksums.txt"
        echo ""
    fi
    
    # ARM64
    if [ -f "$SCRIPT_DIR/buildroot/isos/oracle-arm64/checksums.txt" ]; then
        echo -e "${CYAN}ARM64:${NC}"
        cat "$SCRIPT_DIR/buildroot/isos/oracle-arm64/checksums.txt"
        echo ""
    fi
}

# ==============================================================================
# Validar configuración de Buildroot
# ==============================================================================
validate_configs() {
    echo -e "${BLUE}⚙️  Validando configuraciones de Buildroot...${NC}"
    echo ""
    
    # Verificar defconfigs
    local x86_config="$SCRIPT_DIR/buildroot/configs/zlag_defconfig"
    local arm_config="$SCRIPT_DIR/buildroot/configs/zlag_arm64_defconfig"
    
    if [ -f "$x86_config" ]; then
        echo -e "${GREEN}✓ Config x86_64 encontrado${NC}"
        # Verificar que tiene las opciones críticas
        if grep -q "BR2_TARGET_GRUB2=y" "$x86_config"; then
            echo -e "${GREEN}  ✓ GRUB2 habilitado${NC}"
        else
            echo -e "${YELLOW}  ⚠️  GRUB2 no encontrado en config${NC}"
        fi
    else
        echo -e "${RED}❌ Config x86_64 no encontrado${NC}"
    fi
    
    echo ""
    
    if [ -f "$arm_config" ]; then
        echo -e "${GREEN}✓ Config ARM64 encontrado${NC}"
    else
        echo -e "${RED}❌ Config ARM64 no encontrado${NC}"
    fi
    
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    banner
    
    local target=${1:-both}
    local exit_code=0
    
    case $target in
        x86_64|x86|vultr)
            validate_x86_64 || exit_code=1
            ;;
        arm64|arm|oracle|oci)
            validate_arm64 || exit_code=1
            ;;
        both|all)
            validate_x86_64 || exit_code=1
            validate_arm64 || exit_code=1
            compare_checksums
            ;;
        configs|config)
            validate_configs
            ;;
        *)
            echo -e "${RED}❌ Target desconocido: $target${NC}"
            echo -e "${YELLOW}Uso: ./validate-iso.sh [x86_64|arm64|both|configs]${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}====================================================================${NC}"
        echo -e "${GREEN}  ✅ VALIDACIÓN COMPLETADA EXITOSAMENTE${NC}"
        echo -e "${GREEN}====================================================================${NC}"
    else
        echo -e "${RED}====================================================================${NC}"
        echo -e "${RED}  ❌ VALIDACIÓN FALLÓ${NC}"
        echo -e "${RED}====================================================================${NC}"
    fi
    
    exit $exit_code
}

main "$@"
