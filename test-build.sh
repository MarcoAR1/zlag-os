#!/bin/bash
# ==============================================================================
# 🧪 Test Runner - Script de conveniencia para testear builds localmente
# ==============================================================================
# Este script facilita el testing de la generación de ISOs sin tener que
# recordar los comandos de Docker completos.
#
# Uso:
#   ./test-build.sh build          # Construir la imagen Docker
#   ./test-build.sh x86_64         # Testear solo x86_64
#   ./test-build.sh arm64          # Testear solo ARM64
#   ./test-build.sh both           # Testear ambas arquitecturas
#   ./test-build.sh clean          # Limpiar outputs de build
#   ./test-build.sh shell          # Abrir shell interactivo en el container
# ==============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DOCKER_IMAGE="zgate-builder:test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Funciones auxiliares
# ==============================================================================
banner() {
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${CYAN}  🧪 Z-GATE BUILD TEST RUNNER${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo ""
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no está instalado${NC}"
        echo -e "${YELLOW}Instala Docker Desktop: https://www.docker.com/products/docker-desktop${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker no está corriendo${NC}"
        echo -e "${YELLOW}Inicia Docker Desktop${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Docker está disponible${NC}"
}

check_binaries() {
    echo -e "${YELLOW}Verificando binarios del agent...${NC}"
    
    if [ ! -f "$SCRIPT_DIR/bin/z-gate-agent-x86_64" ]; then
        echo -e "${RED}❌ Falta: bin/z-gate-agent-x86_64${NC}"
        echo -e "${YELLOW}Ejecuta 'make update-agent' en el repo privado primero${NC}"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/bin/z-gate-agent-arm64" ]; then
        echo -e "${RED}❌ Falta: bin/z-gate-agent-arm64${NC}"
        echo -e "${YELLOW}Ejecuta 'make update-agent' en el repo privado primero${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Binarios del agent encontrados${NC}"
    ls -lh "$SCRIPT_DIR/bin/z-gate-agent-"*
    echo ""
}

# ==============================================================================
# Comandos
# ==============================================================================
cmd_build() {
    echo -e "${BLUE}🔨 Construyendo imagen Docker de test...${NC}"
    echo ""
    
    docker build -f "$SCRIPT_DIR/Dockerfile.test" -t "$DOCKER_IMAGE" "$SCRIPT_DIR"
    
    echo ""
    echo -e "${GREEN}✅ Imagen Docker construida: $DOCKER_IMAGE${NC}"
    echo -e "${CYAN}Ahora puedes ejecutar: ./test-build.sh [x86_64|arm64|both]${NC}"
}

cmd_test() {
    local target=${1:-both}
    
    echo -e "${BLUE}🧪 Iniciando test de build: $target${NC}"
    echo ""
    
    # Preparar variables de entorno (si existen)
    DOCKER_ENV=""
    if [ -n "$ZGATE_SECRET" ]; then
        DOCKER_ENV="$DOCKER_ENV -e ZGATE_SECRET=$ZGATE_SECRET"
        echo -e "${GREEN}✓ Usando ZGATE_SECRET del ambiente${NC}"
    fi
    if [ -n "$VULTR_API_KEY" ]; then
        DOCKER_ENV="$DOCKER_ENV -e VULTR_API_KEY=$VULTR_API_KEY"
        echo -e "${GREEN}✓ Usando VULTR_API_KEY del ambiente${NC}"
    fi
    
    echo ""
    
    # Ejecutar Docker con volumen montado
    docker run --rm \
        -v "$SCRIPT_DIR:/workspace" \
        $DOCKER_ENV \
        "$DOCKER_IMAGE" "$target"
}

cmd_clean() {
    echo -e "${YELLOW}🧹 Limpiando outputs de build...${NC}"
    
    read -p "¿Estás seguro? Esto borrará buildroot/output* y buildroot/isos/ [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$SCRIPT_DIR/buildroot/output"
        rm -rf "$SCRIPT_DIR/buildroot/output_arm64"
        rm -rf "$SCRIPT_DIR/buildroot/isos"
        
        echo -e "${GREEN}✅ Limpieza completada${NC}"
    else
        echo -e "${YELLOW}Operación cancelada${NC}"
    fi
}

cmd_shell() {
    echo -e "${BLUE}🐚 Abriendo shell interactivo en el container...${NC}"
    echo ""
    
    docker run --rm -it \
        -v "$SCRIPT_DIR:/workspace" \
        --entrypoint /bin/bash \
        "$DOCKER_IMAGE"
}

cmd_verify() {
    echo -e "${BLUE}🔍 Verificando ISOs generados...${NC}"
    echo ""
    
    # Verificar x86_64
    if [ -f "$SCRIPT_DIR/buildroot/isos/vultr-x86_64/zgate-vultr-x86_64.iso" ]; then
        echo -e "${GREEN}✓ x86_64 ISO encontrado:${NC}"
        ls -lh "$SCRIPT_DIR/buildroot/isos/vultr-x86_64/zgate-vultr-x86_64.iso"
        
        if [ -f "$SCRIPT_DIR/buildroot/isos/vultr-x86_64/checksums.txt" ]; then
            echo -e "${CYAN}Checksums:${NC}"
            cat "$SCRIPT_DIR/buildroot/isos/vultr-x86_64/checksums.txt"
        fi
    else
        echo -e "${YELLOW}⚠️  x86_64 ISO no encontrado${NC}"
    fi
    
    echo ""
    
    # Verificar ARM64
    if [ -f "$SCRIPT_DIR/buildroot/isos/oracle-arm64/zgate-oracle-arm64.ext4" ]; then
        echo -e "${GREEN}✓ ARM64 imagen encontrada:${NC}"
        ls -lh "$SCRIPT_DIR/buildroot/isos/oracle-arm64/zgate-oracle-arm64.ext4"
        
        if [ -f "$SCRIPT_DIR/buildroot/isos/oracle-arm64/checksums.txt" ]; then
            echo -e "${CYAN}Checksums:${NC}"
            cat "$SCRIPT_DIR/buildroot/isos/oracle-arm64/checksums.txt"
        fi
    else
        echo -e "${YELLOW}⚠️  ARM64 imagen no encontrada${NC}"
    fi
}

cmd_help() {
    echo -e "${CYAN}Uso: ./test-build.sh [comando]${NC}"
    echo ""
    echo "Comandos disponibles:"
    echo "  build          Construir la imagen Docker de test"
    echo "  x86_64         Testear generación de ISO x86_64 (Vultr)"
    echo "  arm64          Testear generación de imagen ARM64 (Oracle)"
    echo "  both           Testear ambas arquitecturas (por defecto)"
    echo "  clean          Limpiar outputs de build"
    echo "  shell          Abrir shell interactivo en el container"
    echo "  verify         Verificar ISOs generados y sus checksums"
    echo "  help           Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./test-build.sh build          # Primera vez"
    echo "  ./test-build.sh x86_64         # Test rápido x86_64"
    echo "  ./test-build.sh both           # Test completo"
    echo "  ./test-build.sh verify         # Verificar resultados"
    echo ""
    echo "Variables de entorno opcionales:"
    echo "  export ZGATE_SECRET=xxx        # Secret para el agent"
    echo "  export VULTR_API_KEY=xxx       # API key de Vultr"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    banner
    
    COMMAND=${1:-help}
    
    case $COMMAND in
        build)
            check_docker
            cmd_build
            ;;
        x86_64|x86|vultr)
            check_docker
            check_binaries
            cmd_test "x86_64"
            ;;
        arm64|arm|oracle|oci)
            check_docker
            check_binaries
            cmd_test "arm64"
            ;;
        both|all|test)
            check_docker
            check_binaries
            cmd_test "both"
            ;;
        clean)
            cmd_clean
            ;;
        shell)
            check_docker
            cmd_shell
            ;;
        verify)
            cmd_verify
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            echo -e "${RED}❌ Comando desconocido: $COMMAND${NC}"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
