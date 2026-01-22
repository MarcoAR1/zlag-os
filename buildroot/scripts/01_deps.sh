#!/bin/bash
# scripts/01_deps.sh

check_dependencies() {
    echo -e "${BLUE}[🔍] Verificando dependencias del Host...${NC}"
    local DEPS="build-essential libncurses5-dev libgmp-dev libmpfr-dev libmpc-dev libssl-dev bison flex texinfo unzip rsync bc qemu-system-x86"
    local MISSING=""
    
    for pkg in $DEPS; do
        if ! dpkg -s $pkg >/dev/null 2>&1; then
            MISSING="$MISSING $pkg"
        fi
    done
    
    if [ -n "$MISSING" ]; then
        echo -e "${YELLOW}[!] Faltan paquetes. Instalando...${NC}"
        sudo apt update && sudo apt install -y $MISSING
    fi

    echo -e "${BLUE}[🔍] Verificando código del Agente Go...${NC}"
    if [ ! -d "$AGENT_SRC_DIR" ]; then
        echo -e "${RED}[✘] ERROR: No encuentro el código del agente en $AGENT_SRC_DIR${NC}"
        exit 1
    fi
}