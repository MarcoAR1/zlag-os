#!/bin/bash
# ==============================================================================
#  Z-Gate Docker Builder - Compila Buildroot ISOs desde macOS/Windows
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="zgate-buildroot-builder"
ARCHITECTURE="${2:-x86_64}"  # x86_64 o arm64

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}     🐳 Z-Gate Docker Builder for macOS/Windows     ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado${NC}"
    echo "Instalar desde: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Build Docker image if not exists
if [ -z "$(docker images -q $IMAGE_NAME 2>/dev/null)" ]; then
    echo -e "${YELLOW}🐳 Construyendo imagen Docker (primera vez, ~3 min)...${NC}"
    docker build -t $IMAGE_NAME -f "$SCRIPT_DIR/Dockerfile.build" "$SCRIPT_DIR"
    echo -e "${GREEN}✅ Imagen Docker lista${NC}"
else
    echo -e "${GREEN}✅ Usando imagen Docker existente${NC}"
fi

# Verificar secrets
if [ ! -f "$SCRIPT_DIR/.secrets" ]; then
    echo -e "${YELLOW}⚠️  Archivo .secrets no encontrado, creando template...${NC}"
    cat > "$SCRIPT_DIR/.secrets" <<EOF
export ZGATE_SECRET="your-secret-key-here"
export VULTR_API_KEY="your-vultr-api-key"
export MAX_MINUTES="120"
EOF
    echo -e "${YELLOW}📝 Edita buildroot/.secrets con tus valores reales${NC}"
fi

# Función de ayuda
show_help() {
    cat <<EOF
${GREEN}Uso:${NC}
  ./docker-build.sh <command> [architecture]

${GREEN}Comandos:${NC}
  build       - Build completo desde cero
  update      - Build incremental (rápido)
  clean       - Limpiar outputs
  shell       - Abrir shell interactivo en container

${GREEN}Arquitecturas:${NC}
  x86_64      - Vultr VPS (default)
  arm64       - Oracle Cloud Ampere A1
  both        - Compilar ambas

${GREEN}Ejemplos:${NC}
  ./docker-build.sh update x86_64    # Build rápido x86_64
  ./docker-build.sh build arm64      # Build completo ARM64
  ./docker-build.sh shell            # Shell interactivo
EOF
}

# Parsear argumentos
COMMAND="${1:-update}"

case $COMMAND in
    build|update|clean)
        SCRIPT="setup.sh"
        if [ "$ARCHITECTURE" == "arm64" ]; then
            SCRIPT="setup_arm.sh"
        fi
        
        echo -e "${BLUE}🚀 Ejecutando: ./$SCRIPT $COMMAND${NC}"
        echo -e "${BLUE}Arquitectura: $ARCHITECTURE${NC}"
        echo ""
        
        # Run build inside Docker
        docker run --rm -it \
            -v "$PROJECT_ROOT:/build" \
            -v "$SCRIPT_DIR/dl:/build/buildroot/dl" \
            -w /build/buildroot \
            --user "$(id -u):$(id -g)" \
            $IMAGE_NAME \
            bash -c "./$SCRIPT $COMMAND"
        
        # Verificar resultado
        if [ "$ARCHITECTURE" == "x86_64" ]; then
            ISO_PATH="$SCRIPT_DIR/isos/vultr-x86_64/zgate-vultr-x86_64.iso"
            if [ -f "$ISO_PATH" ]; then
                SIZE=$(du -h "$ISO_PATH" | cut -f1)
                echo -e "${GREEN}✅ ISO generada: $SIZE${NC}"
                echo -e "${GREEN}   $ISO_PATH${NC}"
            fi
        else
            IMG_PATH="$SCRIPT_DIR/isos/oracle-arm64/zgate-oracle-arm64.ext4"
            if [ -f "$IMG_PATH" ]; then
                SIZE=$(du -h "$IMG_PATH" | cut -f1)
                echo -e "${GREEN}✅ Imagen ARM64 generada: $SIZE${NC}"
                echo -e "${GREEN}   $IMG_PATH${NC}"
            fi
        fi
        ;;
    
    shell)
        echo -e "${BLUE}🐚 Abriendo shell interactivo en Docker...${NC}"
        docker run --rm -it \
            -v "$PROJECT_ROOT:/build" \
            -v "$SCRIPT_DIR/dl:/build/buildroot/dl" \
            -w /build/buildroot \
            --user "$(id -u):$(id -g)" \
            $IMAGE_NAME \
            /bin/bash
        ;;
    
    both)
        echo -e "${BLUE}📦 Compilando ambas arquitecturas...${NC}"
        $0 update x86_64
        $0 update arm64
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        echo -e "${RED}❌ Comando desconocido: $COMMAND${NC}"
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Proceso completado${NC}"
