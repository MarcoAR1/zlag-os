#!/bin/bash
# ==============================================================================
# 🚀 zlag OS - Smart Cache Injection Entrypoint (Production Ready)
# ==============================================================================
# Este script se ejecuta dentro del contenedor pre-compilado.
# 1. Recibe el binario de Go (vía volumen montado).
# 2. Lo inyecta en el overlay del sistema de archivos.
# 3. Fuerza a Buildroot a re-empaquetar la ISO/Imagen en segundos.
# ==============================================================================

set -e

# Colores para un log profesional en GitHub Actions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# La arquitectura viene del Dockerfile (ENV ZLAG_ARCH)
ARCH=${ZLAG_ARCH:-"unknown"}

banner() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE} 🏗️  ZLAG OS FINAL ASSEMBLER | Arch: ${YELLOW}${ARCH}${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

sync_agent() {
    echo -e "${BLUE}[1/3] 📦 Inyectando binario del Agente...${NC}"
    
    # RUTA ORIGEN: Mapeada por el Workflow
    # El archivo viene directamente montado en /zlag/bin/z-lag-agent
    SOURCE_BIN="/zlag/bin/z-lag-agent"
    
    # RUTA DESTINO: Overlay de Buildroot dentro del contenedor
    DEST_DIR="/zlag/board/zlag/rootfs-overlay/usr/bin"
    DEST_BIN="${DEST_DIR}/z-lag-agent"

    # Verificar si el volumen se montó correctamente
    if [[ ! -f "$SOURCE_BIN" ]]; then
        echo -e "${RED}❌ Error: No se encontró el binario en $SOURCE_BIN${NC}"
        echo -e "${YELLOW}Asegúrate de que el volumen esté bien mapeado en el docker run.${NC}"
        exit 1
    fi

    # Asegurar existencia del directorio en el overlay
    mkdir -p "$DEST_DIR"

    # Copiar con preservación de atributos y dar permisos de ejecución
    cp -p "$SOURCE_BIN" "$DEST_BIN"
    chmod +x "$DEST_BIN"
    
    echo -e "${GREEN}   ✓ Agente inyectado correctamente en el overlay.${NC}"
}

force_rootfs_rebuild() {
    echo -e "${BLUE}[2/3] 🧹 Limpiando caché de imágenes previas...${NC}"
    
    # Eliminamos el binario antiguo en el target real para forzar la copia del nuevo overlay
    rm -f /zlag/output/target/usr/bin/z-lag-agent

    # Borramos los archivos de imagen previos para que 'make' los genere de nuevo
    # Esto no borra la compilación del kernel, solo el empaquetado final.
    rm -f /zlag/output/images/rootfs.*
    rm -f /zlag/output/images/*.iso
    rm -f /zlag/output/images/*.ext4
    rm -f /zlag/output/images/*.tar.gz
    
    # Eliminamos sellos de control de Buildroot para el paso de target y post-build
    find /zlag/output/build -name ".stamp_target_installed" -delete
    find /zlag/output/build -name ".stamp_images_installed" -delete
    
    echo -e "${GREEN}   ✓ Sistema listo para re-empaquetado rápido.${NC}"
}

run_make() {
    echo -e "${BLUE}[3/3] 🔨 Generando empaquetado final...${NC}"
    
    # Ejecutamos make dentro de /zlag
    # Al estar todo pre-compilado, esto tardará ~30-60 segundos
    if make; then
        echo -e "${GREEN}============================================================${NC}"
        echo -e "${GREEN} ✅ ENSAMBLAJE COMPLETADO CON ÉXITO${NC}"
        echo -e "${GREEN}============================================================${NC}"
        
        # Listar resultados para el log de GitHub
        ls -lh /zlag/output/images/ | grep -E "\.(iso|ext4|tar\.gz)$"
    else
        echo -e "${RED}❌ Error: Falló el comando 'make' durante el empaquetado.${NC}"
        exit 1
    fi
}

# --- EJECUCIÓN ---

banner

# Si se pasan argumentos extras al contenedor (ej: /bin/bash), se ejecutan y el script frena.
if [[ "$#" -gt 0 ]]; then
    echo -e "${YELLOW} entrando en modo manual...${NC}"
    exec "$@"
fi

sync_agent
force_rootfs_rebuild
run_make