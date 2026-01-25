#!/bin/bash
# ==============================================================================
# 🚀 Docker Build Entrypoint - Smart Cache Injection
# ==============================================================================

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# La arquitectura viene definida por el Dockerfile (ENV TARGET_ARCH)
ARCH=${TARGET_ARCH:-"unknown"}

banner() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE} 🚀 Z-GATE BUILDER | Arch: ${YELLOW}${ARCH}${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

sync_agent() {
    echo -e "${BLUE}[1/3] 📦 Inyectando binario del Agente...${NC}"
    
    SOURCE_BIN="/workspace/bin/z-gate-agent-${ARCH}"
    DEST_DIR="board/zgate/rootfs-overlay/usr/bin"
    DEST_BIN="${DEST_DIR}/z-gate-agent"

    # Verificar origen
    if [[ ! -f "$SOURCE_BIN" ]]; then
        echo -e "${RED}❌ Error: No se encuentra el binario en: $SOURCE_BIN${NC}"
        echo -e "${YELLOW}   Asegúrate de que el Job de compilación de Go generó el nombre correcto.${NC}"
        ls -l /workspace/bin/
        exit 1
    fi

    # Verificar destino
    if [[ ! -d "$DEST_DIR" ]]; then
        echo -e "${YELLOW}⚠ Creando directorio de destino: $DEST_DIR${NC}"
        mkdir -p "$DEST_DIR"
    fi

    # Copiar y dar permisos
    cp "$SOURCE_BIN" "$DEST_BIN"
    chmod +x "$DEST_BIN"
    echo -e "${GREEN}   ✓ Agente inyectado exitosamente.${NC}"
}

force_rootfs_rebuild() {
    echo -e "${BLUE}[2/3] 🧹 Limpiando sellos de RootFS...${NC}"
    
    # Truco de Buildroot: Borrar estos archivos obliga a regenerar la imagen final
    # sin recompilar todo el software ni el kernel.
    rm -f output/build/linux-custom/.stamp_images_installed
    rm -f output/images/rootfs.*
    rm -f output/images/*.iso
    rm -f output/images/*.tar.gz
    rm -f output/images/Image
    rm -f output/images/bzImage
    
    # Borrar target instalado para forzar copia del overlay
    rm -rf output/target/usr/bin/z-gate-agent
    
    echo -e "${GREEN}   ✓ Limpieza lista para re-empaquetado.${NC}"
}

run_make() {
    echo -e "${BLUE}[3/3] 🔨 Generando Imagen Final...${NC}"
    
    # Al ejecutar make, Buildroot verá que falta la imagen final y la creará
    # usando el nuevo overlay con el agente actualizado.
    if make; then
        echo -e "${GREEN}============================================================${NC}"
        echo -e "${GREEN} ✅ BUILD EXITOSO${NC}"
        echo -e "${GREEN}    Imagen disponible en: output/images/${NC}"
        echo -e "${GREEN}============================================================${NC}"
        
        # Listar lo generado para confirmar
        ls -lh output/images/
    else
        echo -e "${RED}❌ Error durante el ensamblaje final.${NC}"
        exit 1
    fi
}

# ==============================================================================
# Lógica Principal
# ==============================================================================

banner

# Si pasamos argumentos al docker run, ejecutamos eso (modo debug)
if [[ "$#" -gt 0 ]]; then
    exec "$@"
fi

# Modo por defecto (sin argumentos): Inyectar y Construir
sync_agent
force_rootfs_rebuild
run_make