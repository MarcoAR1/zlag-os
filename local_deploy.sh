#!/bin/bash
# ==============================================================================
# 🚀 ZLAG DOCKER-TURBO (Optimizado para i5-13600KF + GH Release)
# ==============================================================================
set -e

# Configuración
REPO_OWNER="marcoar1"
REPO_NAME="zlag-os"
TAG_NAME="iso-$(date +'%Y%m%d-%H%M')"
BASE_IMAGE="zlag-buildroot-base:latest" # La que creamos con 'make build-base'

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE} 🏗️  ZLAG DOCKER BUILDER | POWERED BY i5-13600KF${NC}"
echo -e "${BLUE}============================================================${NC}"

# 1. Preparación de carpetas locales para los artefactos
mkdir -p release_artifacts
rm -rf release_artifacts/*

build_arch_docker() {
    ARCH=$1
    DEFCONFIG=$2
    OUTPUT_FILE=$3
    
    echo -e "\n${BLUE}------------------------------------------------------------${NC}"
    echo -e "${GREEN}🚀 Compilando Arquitectura: ${YELLOW}$ARCH${NC} (via Docker)"
    
    # Inyectamos el binario de Go en la carpeta compartida antes de arrancar
    # Esto asegura que el contenedor lo vea en board/zlag/rootfs-overlay/usr/bin o donde lo mapees
    echo -e "${YELLOW}📥 Preparando binario para inyección...${NC}"
    mkdir -p buildroot/output/target/usr/bin
    cp bin/z-lag-agent-$ARCH buildroot/output/target/usr/bin/z-lag-agent
    chmod +x buildroot/output/target/usr/bin/z-lag-agent

    # EJECUCIÓN DEL CONTENEDOR A MÁXIMA POTENCIA
    echo -e "${GREEN}🔨 Arrancando contenedor con 20 hilos y 16GB RAM...${NC}"
    
    docker run --rm \
        --privileged \
        --cpus="20" \
        --memory="16g" \
        --memory-swap="20g" \
        -v $(pwd):/workspace \
        -v zlag-ccache:/buildroot/dl/ccache \
        -e ARCH=$ARCH \
        -e BR2_JLEVEL=20 \
        $BASE_IMAGE /bin/bash -c "
            cd /workspace/buildroot && \
            make $DEFCONFIG && \
            make -j20
        "

    # Recolectar el resultado desde el volumen compartido
    echo -e "${GREEN}📦 Extrayendo artefacto de la carpeta buildroot/output/images/...${NC}"
    if [ "$ARCH" == "x86_64" ]; then
        cp buildroot/output/images/rootfs.iso9660 release_artifacts/$OUTPUT_FILE
    else
        # Buscamos ext4 o tar generado
        IMAGE_GEN=$(find buildroot/output/images -maxdepth 1 -type f \( -name "*.ext*" -o -name "rootfs.tar" \) | head -n 1)
        cp "$IMAGE_GEN" release_artifacts/$OUTPUT_FILE
    fi
}

# 2. Ejecutar Builds secuenciales para no saturar el NVMe
build_arch_docker "x86_64" "zlag_defconfig" "zlag-vultr-x86_64.iso"
build_arch_docker "arm64" "zlag_arm64_defconfig" "zlag-oracle-arm64.ext4"

# 3. GitHub Release (Desde tu PC, fuera de Docker)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}============================================================${NC}"
echo -e "${GREEN}[4/4] ☁️  Subiendo Release a GitHub...${NC}"

gh release create "$TAG_NAME" \
    ./release_artifacts/* \
    --repo "$REPO_OWNER/$REPO_NAME" \
    --title "Z-Lag OS Production - $TAG_NAME" \
    --notes "Build generado vía Docker optimizado (i5-13600KF). Agente inyectado."

# 4. Limpieza opcional de la carpeta de trabajo de Buildroot
echo -e "\n${YELLOW}🧹 Limpiando temporales de buildroot...${NC}"
# No borramos todo para mantener el cache de .config, pero limpiamos imágenes
rm -rf buildroot/output/images/*

echo -e "\n${BLUE}============================================================${NC}"
echo -e "${GREEN} 🎉 ¡RELEASE PUBLICADO!${NC}"
echo -e "🔗 URL: https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/$TAG_NAME"
echo -e "${BLUE}============================================================${NC}"