#!/bin/bash
# ==============================================================================
# 🚀 zlag OS - Smart Cache Injection Entrypoint
# ==============================================================================
# Este script se ejecuta dentro del contenedor pre-compilado.
# 1. Recibe el binario compilado de Go (desde el volumen montado).
# 2. Lo inyecta en el overlay del sistema de archivos.
# 3. Fuerza a Buildroot a re-empaquetar la ISO/Imagen sin recompilar el Kernel.
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
    echo -e "${BLUE} 🚀 ZLAG OS BUILDER | Arch: ${YELLOW}${ARCH}${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

sync_agent() {
    echo -e "${BLUE}[1/3] 📦 Inyectando binario del Agente...${NC}"
    
    # Ruta en el volumen montado por GitHub Actions
    SOURCE_BIN="/workspace/bin/z-lag-agent-${ARCH}"
    
    # --- CORRECCIÓN CRÍTICA: zlag -> zlag ---
    DEST_DIR="board/zlag/rootfs-overlay/usr/bin"
    DEST_BIN="${DEST_DIR}/z-lag-agent"

    # Verificar origen (Binario de Go)
    if [[ ! -f "$SOURCE_BIN" ]]; then
        echo -e "${RED}❌ Error: No se encuentra el binario en: $SOURCE_BIN${NC}"
        echo -e "${YELLOW}   Asegúrate de que el Job 'build-agent' generó el nombre correcto.${NC}"
        echo -e "${YELLOW}   Contenido de /workspace/bin/:${NC}"
        ls -l /workspace/bin/ 2>/dev/null || echo "   (Directorio vacío o no montado)"
        exit 1
    fi

    # Verificar destino (Overlay de Buildroot)
    if [[ ! -d "$DEST_DIR" ]]; then
        echo -e "${YELLOW}⚠ El directorio de destino no existía, creándolo: $DEST_DIR${NC}"
        mkdir -p "$DEST_DIR"
    fi

    # Copiar y dar permisos
    cp "$SOURCE_BIN" "$DEST_BIN"
    chmod +x "$DEST_BIN"
    echo -e "${GREEN}   ✓ Agente ($ARCH) inyectado exitosamente.${NC}"
}

force_rootfs_rebuild() {
    echo -e "${BLUE}[2/3] 🧹 Limpiando sellos de RootFS...${NC}"
    
    # 1. Borramos la versión anterior del agente en el 'target' (sistema de archivos temporal)
    rm -rf output/target/usr/bin/z-lag-agent

    # 2. Borramos los sellos (.stamp) para obligar a Buildroot a volver a copiar el overlay
    #    y re-generar las imágenes finales.
    #    NOTA: No borramos los objetos del Kernel, solo los indicadores de "finalizado".
    
    # Forzar paso de ensamblaje de target
    rm -f output/build/.rootfs_build_start_time
    
    # Forzar generación de imágenes de sistema de archivos (ext4, iso, cpio)
    rm -f output/images/rootfs.*
    rm -f output/images/*.iso
    rm -f output/images/*.tar.gz
    
    # Opcional: Si el kernel necesita ser re-copiado a output/images
    # rm -f output/images/Image output/images/bzImage 
    
    echo -e "${GREEN}   ✓ Limpieza lista para re-empaquetado rápido.${NC}"
}

run_make() {
    echo -e "${BLUE}[3/3] 🔨 Generando Imagen Final...${NC}"
    
    # Al ejecutar make, Buildroot detectará que faltan las imágenes finales
    # y las regenerará usando el nuevo overlay.
    if make; then
        echo -e "${GREEN}============================================================${NC}"
        echo -e "${GREEN} ✅ BUILD EXITOSO${NC}"
        echo -e "${GREEN}    Archivos generados en output/images/:${NC}"
        echo -e "${GREEN}============================================================${NC}"
        
        # Mostrar resultados con tamaño para log de CI
        cd output/images
        ls -lh | grep -E "\.(iso|img|ext4|tar\.gz)$" || ls -lh
    else
        echo -e "${RED}❌ Error durante el ensamblaje final.${NC}"
        exit 1
    fi
}

# ==============================================================================
# Lógica Principal
# ==============================================================================

banner

# Si pasamos argumentos al docker run, ejecutamos eso (modo debug manual)
if [[ "$#" -gt 0 ]]; then
    exec "$@"
fi

# Modo Automático
sync_agent
force_rootfs_rebuild
run_make