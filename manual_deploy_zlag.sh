#!/bin/bash
# ==============================================================================
# 🚀 ZLAG MANUAL DEPLOYER (Modo Ahorro de Disco & Hash Sincronizado)
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

# 2. CALCULAR HASH DE CONFIGURACIÓN (Sincronizado con GitHub)
# ------------------------------------------------------------------------------
echo -e "\n${GREEN}[2/3] Calculando Hash Único de Configuración...${NC}"

# Definimos las fuentes exactas que afectan la compilación
HASH_SOURCE="buildroot/scripts buildroot/configs buildroot/board Dockerfile.compiled"

# Verificación de carpetas antes de calcular
for item in $HASH_SOURCE; do
    if [ ! -e "$item" ]; then
        echo -e "${RED}❌ Error: No se encuentra '$item'. Revisa tu estructura de carpetas.${NC}"
        exit 1
    fi
done

# Generamos el Hash de 16 caracteres (Igual que en el .yml)
HASH=$(find $HASH_SOURCE -type f -print0 | sort -z | xargs -0 cat | sha256sum | head -c 16)

echo -e "   Fuentes analizadas correctamente."
echo -e "🔑 Hash generado: ${BLUE}$HASH${NC}"

# 3. CONSTRUIR KERNELS (Bucle secuencial con limpieza inmediata)
# ------------------------------------------------------------------------------
build_kernel_and_clean() {
    ARCH=$1
    FULL_TAG="ghcr.io/$USERNAME/zlag-compiled-$ARCH:$HASH"
    
    echo -e "\n${BLUE}------------------------------------------------------------${NC}"
    echo -e "${GREEN}[3/3] Procesando Arquitectura: ${YELLOW}$ARCH${NC}"
    echo -e "🏷️  Tag: $FULL_TAG"
    
    # A. CONSTRUIR
    echo -e "${YELLOW}🔨 Compilando... (Asegúrate de tener ~30GB libres)${NC}"
    docker build -f Dockerfile.compiled \
        --build-arg BASE_IMAGE=$BASE_IMAGE \
        --build-arg ARCH=$ARCH \
        -t $FULL_TAG .
        
    # B. SUBIR
    echo -e "${GREEN}☁️  Subiendo imagen compilada a GHCR...${NC}"
    docker push $FULL_TAG

    # C. LIMPIEZA DE DISCO (Vital para tu WSL)
    echo -e "${YELLOW}🧹 Liberando espacio: Borrando imagen local $ARCH...${NC}"
    docker rmi $FULL_TAG
    
    echo -e "${YELLOW}🧹 Purgando caché de construcción...${NC}"
    docker builder prune -f
    
    echo -e "${GREEN}✅ Ciclo completado para $ARCH. Espacio recuperado.${NC}"
}

# Ejecución secuencial
build_kernel_and_clean "x86_64"
build_kernel_and_clean "arm64"

echo -e "\n${BLUE}============================================================${NC}"
echo -e "${BLUE} 🎉 ÉXITO TOTAL: Kernels subidos con el Hash $HASH${NC}"
echo -e "${BLUE}    Ahora el Workflow de ISOs reconocerá este hash automáticamente.${NC}"
echo -e "${BLUE}============================================================${NC}"