#!/bin/bash
# scripts/00_env.sh

set -euo pipefail

# Configurar TERM para entornos no-interactivos (GitHub Actions, Docker)
export TERM=${TERM:-linux}

# --- RUTAS ---
export ISO_PATH="output/images/rootfs.iso9660"
export KERNEL_BUILD_DIR="output/build/linux-6.1.100"
export AGENT_SRC_DIR="../zgate/agent"
export JOBS=$(nproc)

# --- COLORES ---
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Limpieza de PATH para WSL
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/mnt/' | tr '\n' ':' | sed 's/:$//')

load_secrets() {
    # GitHub Actions / Docker: los secretos vienen como variables de entorno
    if [ -n "${ZGATE_SECRET:-}" ]; then
        echo -e "${GREEN}[🔐] Usando secretos de variables de entorno (GitHub Actions/Docker)${NC}"
        return 0
    fi
    
    # Build local: intentar cargar desde archivos .env
    if [ -f "$AGENT_SRC_DIR/.env" ]; then
        echo -e "${GREEN}[🔐] Cargando secretos desde $AGENT_SRC_DIR/.env ...${NC}"
        source "$AGENT_SRC_DIR/.env"
    elif [ -f ".env" ]; then
        echo -e "${GREEN}[🔐] Cargando secretos desde .env local...${NC}"
        source ".env"
    elif [ -f ".secrets" ]; then
        echo -e "${GREEN}[🔐] Cargando secretos desde .secrets (Docker testing)${NC}"
        source ".secrets"
    else
        echo -e "${YELLOW}[⚠️] No se encontró archivo .env, usando valor por defecto${NC}"
        export ZGATE_SECRET="zgate-dev-default"
    fi
}