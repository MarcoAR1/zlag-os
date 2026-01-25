#!/bin/bash
# ==============================================================================
#  🛡️ Z-GATE CORE ORCHESTRATOR v34.0 (MODULAR) - Vultr x86_64
# ==============================================================================

set -euo pipefail

# Configurar TERM para entornos no-interactivos (GitHub Actions)
export TERM=${TERM:-linux}

# ============================================================================
# PATH SANITIZATION
# ============================================================================
clean_path() {
    local NEW_PATH=""
    IFS=':' read -ra PATHS <<< "$PATH"
    for p in "${PATHS[@]}"; do
        if [[ ! "$p" =~ [[:space:]] ]]; then
            if [ -z "$NEW_PATH" ]; then
                NEW_PATH="$p"
            else
                NEW_PATH="$NEW_PATH:$p"
            fi
        fi
    done
    if [ -z "$NEW_PATH" ] || [ $(echo "$NEW_PATH" | tr ':' '\n' | wc -l) -lt 3 ]; then
        NEW_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    fi
    export PATH="$NEW_PATH"
}

clean_path

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$SCRIPT_DIR/isos/vultr-x86_64"

# Importar Módulos
source scripts/00_env.sh
source scripts/01_deps.sh
source scripts/02_config.sh
source scripts/03_agent_install.sh  # <--- CORREGIDO: Importamos el instalador

# Función de Cabecera
header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${CYAN}       🛡️  Z-GATE CORE | ORCHESTRATOR v34.0       ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "Modo: ${YELLOW}$1${NC} | Jobs: ${YELLOW}$JOBS${NC}"
    echo -e "Audio Fix: ${GREEN}ACTIVE${NC}"
    echo -e "----------------------------------------------------"
}

# Lógica de Make
run_full_build() {
    echo -e "${RED}[☢️] LIMPIEZA NUCLEAR DE KERNEL...${NC}"
    rm -rf output/build/linux-6.1.100 
    rm -f output/build/.fragments_list
    rm -f output/images/bzImage

    echo -e "${BLUE}[🛠️] Configurando Buildroot...${NC}"
    make zgate_defconfig
    
    echo -e "${BLUE}[🔨] Compilando (10-15 min)...${NC}"
    make -j$JOBS
}

run_update() {
    echo -e "${YELLOW}[⚡] Actualización Rápida...${NC}"
    configure_system 
    
    # Detectar si output existe (restaurado desde caché)
    if [ -d "output" ] && [ -f "output/.config" ]; then
        echo -e "${GREEN}[📦] Cache detectado, recompilando cambios...${NC}"
        make zgate_defconfig
        make -j$JOBS
    else
        echo -e "${YELLOW}[🔨] No cache found, running full build...${NC}"
        make zgate_defconfig
        make -j$JOBS
    fi
}

# --- CONTROLADOR PRINCIPAL ---

if [ "$1" == "build" ]; then
    header "FULL BUILD"
    check_dependencies
    configure_system
    
    # INSTALACIÓN DEL AGENTE
    # Llamamos a la función de copia del script 03_agent_install.sh
    install_prebuilt_agent "x86_64"
    
    run_full_build

elif [ "$1" == "update" ]; then
    header "UPDATE"
    
    # INSTALACIÓN DEL AGENTE
    # Siempre ejecutamos esto en update para asegurar que el binario sea el más reciente
    install_prebuilt_agent "x86_64"
    
    run_update

elif [ "$1" == "clean" ]; then
    header "LIMPIEZA"
    echo -e "${RED}Borrando output...${NC}"
    rm -rf output
    echo -e "${GREEN}Listo.${NC}"
    exit 0

else
    echo -e "${RED}Uso: ./setup.sh {build|update|clean}${NC}"
    exit 1
fi

# Verificación de ISO
if [ -f "$ISO_PATH" ]; then
    echo -e "${GREEN}[✔] ISO GENERADA: $ISO_PATH ($(du -h $ISO_PATH | cut -f1))${NC}"
    
    echo -e "${YELLOW}Organizing ISOs for Brain deployment...${NC}"
    mkdir -p "$ISO_DIR"
    
    cp "$ISO_PATH" "$ISO_DIR/zgate-vultr-x86_64.iso"
    echo -e "${GREEN}✓ Copied: $ISO_DIR/zgate-vultr-x86_64.iso${NC}"
    
    cd "$ISO_DIR"
    sha256sum zgate-vultr-x86_64.iso > checksums.txt 2>/dev/null || shasum -a 256 zgate-vultr-x86_64.iso > checksums.txt
    echo -e "${GREEN}✓ Generated: $ISO_DIR/checksums.txt${NC}"
    
    echo -e "\n${GREEN}ISOs ready for Brain at:${NC}"
    ls -lh "$ISO_DIR"
else
    echo -e "${RED}[✘] Error: No se generó la ISO en $ISO_PATH.${NC}"
    exit 1
fi