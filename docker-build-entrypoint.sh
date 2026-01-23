#!/bin/bash
# ==============================================================================
# 🚀 Docker Build Entrypoint - Z-Gate ISO Builder (Optimizado)
# ==============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
    [ -n "$TERM" ] && command -v clear >/dev/null 2>&1 && clear
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🚀 Z-GATE OPTIMIZED BUILD${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${BLUE}Usando imagen base pre-construida de Buildroot${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo ""
}

# Validar integridad de binarios
verify_binaries() {
    echo -e "${BLUE}🔐 Verificando integridad de binarios...${NC}"
    
    if [[ -f "/workspace/bin/checksums.sha256" ]]; then
        cd /workspace/bin
        if sha256sum -c checksums.sha256 2>/dev/null; then
            echo -e "${GREEN}✓ Binarios verificados correctamente${NC}"
        else
            echo -e "${RED}❌ ALERTA: Checksums no coinciden - binarios corruptos o modificados${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠ Checksums no encontrados - saltando validación${NC}"
    fi
}

# Copiar configuración del proyecto a Buildroot
sync_config() {
    echo -e "${BLUE}📦 Sincronizando binarios del agent...${NC}"
    
    cd /buildroot
    
    # Crear directorio overlay si no existe
    mkdir -p board/zgate/rootfs-overlay/usr/bin
    
    # Copiar binarios desde workspace montado (si existe)
    if [[ -d "/workspace/bin" ]]; then
        echo -e "${GREEN}✓ Copiando binarios del agent desde /workspace/bin${NC}"
        
        if [[ -f "/workspace/bin/z-gate-agent-x86_64" ]]; then
            cp /workspace/bin/z-gate-agent-x86_64 board/zgate/rootfs-overlay/usr/bin/z-gate-agent
            chmod +x board/zgate/rootfs-overlay/usr/bin/z-gate-agent
            echo -e "${GREEN}  → z-gate-agent (x86_64) copiado${NC}"
        else
            echo -e "${YELLOW}  ⚠ z-gate-agent-x86_64 no encontrado${NC}"
        fi
        
        if [[ -f "/workspace/bin/z-gate-agent-arm64" ]]; then
            cp /workspace/bin/z-gate-agent-arm64 board/zgate/rootfs-overlay/usr/bin/z-gate-agent-arm64
            chmod +x board/zgate/rootfs-overlay/usr/bin/z-gate-agent-arm64
            echo -e "${GREEN}  → z-gate-agent-arm64 copiado${NC}"
        else
            echo -e "${YELLOW}  ⚠ z-gate-agent-arm64 no encontrado${NC}"
        fi
    else
        echo -e "${RED}❌ /workspace/bin no encontrado${NC}"
        echo -e "${YELLOW}Asegúrate de montar el volumen: -v \$(pwd):/workspace${NC}"
        exit 1
    fi
    
    # Verificar que las configuraciones existen (ya fueron pre-generadas)
    if [[ ! -f "configs/zgate_defconfig" ]]; then
        echo -e "${RED}❌ configs/zgate_defconfig no existe${NC}"
        echo -e "${YELLOW}Las configuraciones deberían haberse generado en el Dockerfile${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Configuraciones verificadas${NC}"
}

# Build x86_64
build_x86_64() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🔨 BUILDING x86_64 ISO${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    
    cd /buildroot
    ./setup.sh update
    
    echo -e "${GREEN}✅ x86_64 ISO generado${NC}"
}

# Build ARM64
build_arm64() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🔨 BUILDING ARM64 Image${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    
    cd /buildroot
    ./setup_arm.sh update
    
    echo -e "${GREEN}✅ ARM64 Image generado${NC}"
}

# Main
banner
verify_binaries
sync_config

case "${1:-both}" in
    x86_64)
        build_x86_64
        ;;
    arm64)
        build_arm64
        ;;
    both)
        build_x86_64
        echo ""
        build_arm64
        ;;
    *)
        echo -e "${RED}Uso: $0 {x86_64|arm64|both}${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}====================================================================${NC}"
echo -e "${GREEN}  ✅ BUILD COMPLETADO${NC}"
echo -e "${GREEN}====================================================================${NC}"
