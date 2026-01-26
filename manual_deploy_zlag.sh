#!/bin/bash
# ==============================================================================
# 🚀 ZLAG MANUAL DEPLOYER (Modo Ahorro de Disco)
# ==============================================================================
set -e

USERNAME="marcoar1"
REPO="zlag-os"
BASE_TAG="v1"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE} 🏗️  ZLAG BUILDER: PRE-WARMING CACHE (Low Disk Mode)${NC}"
echo -e "${BLUE}============================================================${NC}"

# 1. CONSTRUIR IMAGEN BASE
# ------------------------------------------------------------------------------
BASE_IMAGE="ghcr.io/$USERNAME/zlag-base:$BASE_TAG"

echo -e "\n${GREEN}[1/3] Procesando Imagen Base ($BASE_IMAGE)...${NC}"
docker build -f Dockerfile.base -t $BASE_IMAGE .
echo -e "${GREEN}Subiendo Base a GHCR...${NC}"
docker push $BASE_IMAGE

# 2. CALCULAR HASH DE CONFIGURACIÓN
# ------------------------------------------------------------------------------
echo -e "\n${GREEN}[2/3] Calculando Hash Único de Configuración...${NC}"

HASH_SOURCE="buildroot/scripts/ Dockerfile.compiled"

if [ ! -d "buildroot/scripts" ]; then
    echo "❌ Error: No encuentro la carpeta 'buildroot/scripts'."
    exit 1
fi

HASH=$(find $HASH_SOURCE -type f -print0 | sort -z | xargs -0 cat | sha256sum | head -c 16)

echo -e "   Fuentes analizadas: $HASH_SOURCE"
echo -e "🔑 Hash generado: ${BLUE}$HASH${NC}"

# 3. CONSTRUIR KERNELS (UNO POR UNO Y LIMPIANDO)
# ------------------------------------------------------------------------------
build_kernel_and_clean() {
    ARCH=$1
    FULL_TAG="ghcr.io/$USERNAME/zlag-compiled-$ARCH:$HASH"
    
    echo -e "\n${BLUE}------------------------------------------------------------${NC}"
    echo -e "${GREEN}[3/3] Procesando Kernel $ARCH...${NC}"
    echo -e "🏷️  Tag: $FULL_TAG"
    
    # A. CONSTRUIR
    echo -e "${YELLOW}🔨 Compilando (Esto ocupará espacio temporalmente)...${NC}"
    docker build -f Dockerfile.compiled \
        --build-arg BASE_IMAGE=$BASE_IMAGE \
        --build-arg ARCH=$ARCH \
        -t $FULL_TAG .
        
    # B. SUBIR
    echo -e "${GREEN}☁️  Subiendo Kernel $ARCH a GHCR...${NC}"
    docker push $FULL_TAG

    # C. LIMPIEZA AGRESIVA (La Clave para tu disco)
    echo -e "${YELLOW}🧹 LIMPIEZA DE EMERGENCIA: Borrando imagen local $ARCH...${NC}"
    docker rmi $FULL_TAG
    
    echo -e "${YELLOW}🧹 LIMPIEZA DE CACHÉ: Borrando capas de compilación intermedias...${NC}"
    # Esto borra el caché del build (los archivos .o gigantes) pero mantiene la imagen base
    docker builder prune -f
    
    echo -e "${GREEN}✅ Espacio recuperado. Listo para la siguiente arquitectura.${NC}"
}

# Ejecutamos secuencialmente con limpieza intermedia
build_kernel_and_clean "x86_64"
build_kernel_and_clean "arm64"

echo -e "\n${BLUE}============================================================${NC}"
echo -e "${BLUE} 🎉 ÉXITO: Cache subido para el Hash $HASH${NC}"
echo -e "${BLUE}    Tu disco debería estar casi igual que al principio.${NC}"
echo -e "${BLUE}============================================================${NC}"