#!/bin/bash
# scripts/01_deps.sh

check_dependencies() {
    echo -e "${BLUE}[🔍] Verificando entorno de compilación (Host/Container)...${NC}"
    
    # Dependencias Base + Kernel 6.1 (libelf-dev) + Cross-Compilation
    local DEPS="build-essential libncurses5-dev libssl-dev libelf-dev bison flex texinfo unzip rsync bc git wget cpio python3"
    
    # Si estamos en x86, añadimos soporte para compilar ARM64 localmente
    if [ "$(uname -m)" == "x86_64" ]; then
         DEPS="$DEPS gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
    fi

    local MISSING=""
    
    # Verificación apt/dpkg (Debian/Ubuntu)
    if command -v dpkg >/dev/null; then
        for pkg in $DEPS; do
            if ! dpkg -s $pkg >/dev/null 2>&1; then
                MISSING="$MISSING $pkg"
            fi
        done
    fi
    
    if [ -n "$MISSING" ]; then
        echo -e "${YELLOW}[!] Paquetes faltantes detectados: $MISSING${NC}"
        
        # Lógica inteligente de instalación (Root vs Sudo)
        if [ "$EUID" -eq 0 ]; then
            # Estamos en Docker o como Root
            apt-get update -qq && apt-get install -y $MISSING
        elif command -v sudo >/dev/null; then
            # Estamos en Desktop local
            echo -e "${YELLOW}    Solicitando sudo para instalar dependencias...${NC}"
            sudo apt-get update -qq && sudo apt-get install -y $MISSING
        else
            echo -e "${RED}[✘] Error Crítico: Faltan dependencias y no hay permisos de root.${NC}"
            echo -e "    Instala manualmente: $MISSING"
            exit 1
        fi
    else
        echo -e "${GREEN}    ✓ Dependencias del sistema: OK${NC}"
    fi

    # NOTA: Se eliminó la verificación de AGENT_SRC_DIR.
    # En la arquitectura Zlag v1.0, el orquestador (setup.sh) verifica 
    # la existencia del BINARIO compilado (bin/z-lag-agent), no del código fuente.
}