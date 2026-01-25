#!/bin/bash
# ==============================================================================
# 🚀 ccache Management Script
# ==============================================================================
# Gestiona el volumen de ccache de Docker para builds optimizados
# ==============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

VOLUME_NAME="zlag-ccache"

show_help() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  🚀 Z-Lag ccache Management                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Comandos disponibles:${NC}"
    echo "  ./ccache-manager.sh stats      Ver estadísticas de ccache"
    echo "  ./ccache-manager.sh clear      Limpiar caché (liberar espacio)"
    echo "  ./ccache-manager.sh size       Ver tamaño del volumen"
    echo "  ./ccache-manager.sh reset      Eliminar y recrear volumen"
    echo ""
}

check_volume() {
    if ! docker volume inspect "$VOLUME_NAME" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Volumen '$VOLUME_NAME' no existe${NC}"
        echo -e "${BLUE}Creando volumen...${NC}"
        docker volume create "$VOLUME_NAME"
        echo -e "${GREEN}✅ Volumen creado${NC}"
    fi
}

show_stats() {
    check_volume
    
    echo -e "${BLUE}📊 Estadísticas de ccache:${NC}"
    echo ""
    
    docker run --rm \
        -v "$VOLUME_NAME:/ccache" \
        alpine sh -c '
            if [ -d /ccache ]; then
                echo "📂 Contenido del volumen:"
                ls -lah /ccache || echo "  (vacío)"
                echo ""
                echo "💾 Tamaño total:"
                du -sh /ccache 2>/dev/null || echo "  0 KB"
            else
                echo "⚠️  Directorio no existe aún"
            fi
        '
}

show_size() {
    check_volume
    
    echo -e "${BLUE}💾 Tamaño del volumen ccache:${NC}"
    
    docker run --rm \
        -v "$VOLUME_NAME:/ccache" \
        alpine du -sh /ccache 2>/dev/null || echo "0 KB"
}

clear_cache() {
    check_volume
    
    echo -e "${YELLOW}⚠️  ¿Seguro que quieres limpiar el caché?${NC}"
    echo -e "${YELLOW}Esto hará que el próximo build sea más lento${NC}"
    read -p "Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🧹 Limpiando caché...${NC}"
        
        docker run --rm \
            -v "$VOLUME_NAME:/ccache" \
            alpine sh -c 'rm -rf /ccache/*'
        
        echo -e "${GREEN}✅ Caché limpiado${NC}"
    else
        echo -e "${YELLOW}Operación cancelada${NC}"
    fi
}

reset_volume() {
    echo -e "${RED}⚠️  ADVERTENCIA: Esto eliminará completamente el volumen${NC}"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🗑️  Eliminando volumen...${NC}"
        docker volume rm "$VOLUME_NAME" 2>/dev/null || true
        
        echo -e "${BLUE}📦 Creando nuevo volumen...${NC}"
        docker volume create "$VOLUME_NAME"
        
        echo -e "${GREEN}✅ Volumen recreado${NC}"
    else
        echo -e "${YELLOW}Operación cancelada${NC}"
    fi
}

# Main
case "${1:-help}" in
    stats)
        show_stats
        ;;
    size)
        show_size
        ;;
    clear)
        clear_cache
        ;;
    reset)
        reset_volume
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando desconocido: $1${NC}"
        show_help
        exit 1
        ;;
esac
