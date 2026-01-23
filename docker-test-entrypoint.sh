#!/bin/bash
# ==============================================================================
# 🚀 Docker Test Entrypoint - Z-Gate ISO Builder
# ==============================================================================
# Replica exactamente el proceso de GitHub Actions para builds locales
# ==============================================================================

set -e

# Arreglar permisos si somos root
if [ "$(id -u)" = "0" ]; then
    echo "⚙️ Configurando permisos del workspace..."
    chown -R builder:builder /workspace 2>/dev/null || true
    # Re-ejecutar este script como usuario builder
    exec su builder -c "/usr/local/bin/entrypoint.sh $@"
fi

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==============================================================================
# Banner
# ==============================================================================
banner() {
    # clear solo si TERM está configurado
    [ -n "$TERM" ] && command -v clear >/dev/null 2>&1 && clear
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🐳 Z-GATE LOCAL BUILD TEST ENVIRONMENT${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${BLUE}Replicando GitHub Actions workflow localmente${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo ""
}

# ==============================================================================
# Verificar que estamos en el directorio correcto
# ==============================================================================
verify_workspace() {
    if [ ! -d "/workspace/buildroot" ]; then
        echo -e "${RED}❌ Error: No se encuentra /workspace/buildroot${NC}"
        echo -e "${YELLOW}Asegúrate de montar el volumen correctamente:${NC}"
        echo -e "${CYAN}docker run -v \$(pwd):/workspace zgate-builder:test${NC}"
        exit 1
    fi
    
    if [ ! -d "/workspace/bin" ]; then
        echo -e "${RED}❌ Error: No se encuentra /workspace/bin${NC}"
        echo -e "${YELLOW}Asegúrate de tener los binarios del agent en bin/${NC}"
        exit 1
    fi
    
    # Crear directorios necesarios (el usuario builder ya tiene permisos)
    echo -e "${BLUE}⚙️  Configurando directorios de trabajo...${NC}"
    mkdir -p /workspace/buildroot/dl
    mkdir -p /workspace/buildroot/output
    mkdir -p /workspace/buildroot/isos
}

# ==============================================================================
# Verificar binarios del agent
# ==============================================================================
verify_agent_binaries() {
    local arch=$1
    local binary=""
    
    if [ "$arch" == "x86_64" ]; then
        binary="/workspace/bin/z-gate-agent-x86_64"
    elif [ "$arch" == "arm64" ]; then
        binary="/workspace/bin/z-gate-agent-arm64"
    fi
    
    if [ ! -f "$binary" ]; then
        echo -e "${RED}❌ Error: Agent binary no encontrado: $binary${NC}"
        echo -e "${YELLOW}Ejecuta 'make update-agent' en el repo privado primero${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Agent binary encontrado: $binary${NC}"
    ls -lh "$binary"
    
    # Copiar al overlay de buildroot (igual que en GitHub Actions)
    local overlay_dir="/workspace/buildroot/board/zgate/rootfs-overlay/usr/bin"
    mkdir -p "$overlay_dir"
    
    if [ "$arch" == "x86_64" ]; then
        cp "$binary" "$overlay_dir/z-gate-agent"
        chmod +x "$overlay_dir/z-gate-agent"
        echo -e "${GREEN}✓ Copiado a overlay: $overlay_dir/z-gate-agent${NC}"
    else
        cp "$binary" "$overlay_dir/z-gate-agent-arm64"
        chmod +x "$overlay_dir/z-gate-agent-arm64"
        echo -e "${GREEN}✓ Copiado a overlay: $overlay_dir/z-gate-agent-arm64${NC}"
    fi
    
    return 0
}

# ==============================================================================
# Crear archivo de secretos (mock para testing)
# ==============================================================================
create_secrets_file() {
    echo -e "${YELLOW}⚙️  Creando archivo de secretos para testing...${NC}"
    
    cd /workspace/buildroot
    
    # Usar valores mock si no existen variables de entorno
    cat > .secrets <<EOF
export ZGATE_SECRET="${ZGATE_SECRET:-test-secret-12345}"
EOF
    
    echo -e "${GREEN}✓ Archivo de secretos creado (valores mock para testing)${NC}"
    
    # Mostrar advertencia si son valores mock
    if [ -z "$ZGATE_SECRET" ]; then
        echo -e "${YELLOW}⚠️  Usando ZGATE_SECRET mock. Para producción, pasa -e ZGATE_SECRET=...${NC}"
    fi
}

# ==============================================================================
# Build x86_64 ISO (Vultr)
# ==============================================================================
build_x86_64() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🔨 BUILDING x86_64 ISO (Vultr)${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo ""
    
    verify_agent_binaries "x86_64" || exit 1
    create_secrets_file
    
    cd /workspace/buildroot
    
    echo -e "${BLUE}[1/3] Ejecutando setup.sh update...${NC}"
    echo -e "${YELLOW}Esto puede tomar 10-15 minutos...${NC}"
    ./setup.sh update 2>&1 | tee /tmp/build-x86_64.log
    
    echo -e "${BLUE}[2/3] Calculando hash del ISO...${NC}"
    if [ -f "isos/vultr-x86_64/zgate-vultr-x86_64.iso" ]; then
        cd isos/vultr-x86_64
        SHA256=$(sha256sum zgate-vultr-x86_64.iso | cut -d' ' -f1)
        SIZE=$(du -h zgate-vultr-x86_64.iso | cut -f1)
        
        echo -e "${GREEN}====================================================================${NC}"
        echo -e "${GREEN}✅ ISO x86_64 generado exitosamente!${NC}"
        echo -e "${GREEN}====================================================================${NC}"
        echo -e "Archivo: zgate-vultr-x86_64.iso"
        echo -e "Tamaño: ${SIZE}"
        echo -e "SHA256: ${SHA256}"
        echo -e "${GREEN}====================================================================${NC}"
        
        # Guardar checksums
        echo "${SHA256}  zgate-vultr-x86_64.iso" > checksums.txt
        echo -e "${GREEN}✓ Checksums guardados en checksums.txt${NC}"
    else
        echo -e "${RED}❌ Error: ISO no generado en isos/vultr-x86_64/${NC}"
        exit 1
    fi
}

# ==============================================================================
# Build ARM64 Image (Oracle Cloud)
# ==============================================================================
build_arm64() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🔨 BUILDING ARM64 IMAGE (Oracle Cloud)${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo ""
    
    verify_agent_binaries "arm64" || exit 1
    create_secrets_file
    
    cd /workspace/buildroot
    
    echo -e "${BLUE}[1/3] Ejecutando setup_arm.sh update...${NC}"
    echo -e "${YELLOW}Esto puede tomar 10-15 minutos...${NC}"
    ./setup_arm.sh update 2>&1 | tee /tmp/build-arm64.log
    
    echo -e "${BLUE}[2/3] Calculando hash de la imagen...${NC}"
    if [ -f "isos/oracle-arm64/zgate-oracle-arm64.ext4" ]; then
        cd isos/oracle-arm64
        SHA256=$(sha256sum zgate-oracle-arm64.ext4 | cut -d' ' -f1)
        SIZE=$(du -h zgate-oracle-arm64.ext4 | cut -f1)
        
        echo -e "${GREEN}====================================================================${NC}"
        echo -e "${GREEN}✅ Imagen ARM64 generada exitosamente!${NC}"
        echo -e "${GREEN}====================================================================${NC}"
        echo -e "Archivo: zgate-oracle-arm64.ext4"
        echo -e "Tamaño: ${SIZE}"
        echo -e "SHA256: ${SHA256}"
        echo -e "${GREEN}====================================================================${NC}"
        
        # Guardar checksums
        echo "${SHA256}  zgate-oracle-arm64.ext4" > checksums.txt
        echo -e "${GREEN}✓ Checksums guardados en checksums.txt${NC}"
    else
        echo -e "${RED}❌ Error: Imagen no generada en isos/oracle-arm64/${NC}"
        exit 1
    fi
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    banner
    verify_workspace
    
    BUILD_TARGET=${1:-both}
    
    case $BUILD_TARGET in
        x86_64|x86|vultr)
            build_x86_64
            ;;
        arm64|arm|oracle|oci)
            build_arm64
            ;;
        both|all)
            build_x86_64
            echo ""
            echo -e "${CYAN}Pausando 5 segundos antes de ARM64...${NC}"
            sleep 5
            build_arm64
            ;;
        *)
            echo -e "${RED}❌ Target desconocido: $BUILD_TARGET${NC}"
            echo -e "${YELLOW}Uso: docker run ... zgate-builder:test [x86_64|arm64|both]${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}====================================================================${NC}"
    echo -e "${GREEN}  ✅ BUILD COMPLETADO!${NC}"
    echo -e "${GREEN}====================================================================${NC}"
    echo ""
    echo -e "${CYAN}Archivos generados en:${NC}"
    if [ "$BUILD_TARGET" == "x86_64" ] || [ "$BUILD_TARGET" == "both" ]; then
        echo -e "  • buildroot/isos/vultr-x86_64/zgate-vultr-x86_64.iso"
    fi
    if [ "$BUILD_TARGET" == "arm64" ] || [ "$BUILD_TARGET" == "both" ]; then
        echo -e "  • buildroot/isos/oracle-arm64/zgate-oracle-arm64.ext4"
    fi
    echo ""
}

main "$@"
