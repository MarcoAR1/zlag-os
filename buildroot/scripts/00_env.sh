#!/bin/bash
# scripts/00_env.sh

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
    if [ -f "$AGENT_SRC_DIR/.env" ]; then
        echo -e "${GREEN}[🔐] Cargando secretos desde $AGENT_SRC_DIR/.env ...${NC}"
        source "$AGENT_SRC_DIR/.env"
    elif [ -f ".env" ]; then
        echo -e "${GREEN}[🔐] Cargando secretos desde .env local...${NC}"
        source ".env"
    else
        echo -e "${RED}[⚠️] ADVERTENCIA: No se encontró archivo .env${NC}"
        export ZGATE_SECRET="zgate-dev-default"
        export VULTR_API_KEY=""
        export MAX_MINUTES="60"
    fi
}