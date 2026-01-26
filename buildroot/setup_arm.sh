#!/bin/bash
# ==============================================================================
# 🛡️ ZLAG CORE ORCHESTRATOR v1.0 - Oracle Cloud ARM64
# ==============================================================================

set -euo pipefail

# Configurar TERM para entornos no-interactivos
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
# Unificamos OUTPUT_DIR para simplificar entrypoint y Docker cache
OUTPUT_DIR="$SCRIPT_DIR/output" 
ISO_DIR="$SCRIPT_DIR/isos/oracle-arm64"

# Importar Módulos
source scripts/00_env.sh
source scripts/01_deps.sh
source scripts/02_config_arm.sh 

# Manejo seguro del instalador de agente
if [ -f "scripts/03_agent_install.sh" ]; then
    source scripts/03_agent_install.sh
else
    # Mock function si el script no existe (para evitar crash en bootstapping)
    install_prebuilt_agent() { echo -e "${YELLOW}[!] Agent installer script missing, skipping injection.${NC}"; }
fi

# Función de Cabecera
header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${CYAN}      🛡️  ZLAG OS CORE | ORCHESTRATOR ARM64        ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "Modo: ${YELLOW}$1${NC} | Jobs: ${YELLOW}$JOBS${NC}"
    echo -e "Target: ${YELLOW}Oracle Cloud (Ampere A1)${NC}"
    echo -e "Output: ${YELLOW}$OUTPUT_DIR${NC}"
    echo -e "----------------------------------------------------"
}

# Lógica de Make (ARM64)
run_full_build() {
    echo -e "${RED}[☢️] LIMPIEZA NUCLEAR DE KERNEL ARM64...${NC}"
    
    # Comandos separados correctamente para evitar errores de sintaxis
    rm -rf output/build/linux-*
    rm -f output/build/.fragments_list
    rm -f output/images/Image

    echo -e "${BLUE}[🛠️] Configurando Buildroot ARM64...${NC}"
    make zlag_arm64_defconfig
    
    echo -e "${BLUE}[🔨] Compilando Kernel y Toolchain...${NC}"
    make -j$JOBS
}

run_update() {
    echo -e "${YELLOW}[⚡] Actualización Rápida ARM64...${NC}"
    configure_system_arm 
    
    # Forzar regeneración de imágenes
    rm -f output/images/rootfs.ext4
    rm -f output/images/rootfs.tar.gz

    if [ -d "output" ] && [ -f "output/.config" ]; then
        echo -e "${GREEN}[📦] Cache detectado, ensamblando imagen...${NC}"
        make zlag_arm64_defconfig
        make -j$JOBS
    else
        echo -e "${YELLOW}[🔨] No cache found, running full build fallback...${NC}"
        make zlag_arm64_defconfig
        make -j$JOBS
    fi
}

# --- CONTROLADOR PRINCIPAL ---

if [ "$1" == "build" ]; then
    header "FULL BUILD"
    check_dependencies
    configure_system_arm
    
    # INSTALACIÓN AGENTE (OPCIONAL EN BUILD)
    # Vital para el Docker Cache: Si no hay binario, no fallamos.
    # Buscamos bin/z-lag-agent-arm64
    if [ -f "bin/z-lag-agent-arm64" ]; then
        install_prebuilt_agent "arm64"
    else
        echo -e "${YELLOW}[!] Agente binario (bin/z-lag-agent-arm64) no encontrado.${NC}"
        echo -e "${YELLOW}    Continuando solo con compilación de Kernel.${NC}"
    fi
    
    run_full_build

elif [ "$1" == "update" ]; then
    header "UPDATE"
    
    # INSTALACIÓN AGENTE (MANDATORIA EN UPDATE)
    install_prebuilt_agent "arm64"
    
    run_update

elif [ "$1" == "clean" ]; then
    header "LIMPIEZA"
    echo -e "${RED}Borrando output...${NC}"
    rm -rf output
    echo -e "${GREEN}Listo.${NC}"
    exit 0

else
    echo -e "${RED}Uso: ./setup_arm.sh {build|update|clean}${NC}"
    exit 1
fi

# ============================================================================
# GESTIÓN DE ARTEFACTOS
# ============================================================================
EXT4_PATH="output/images/rootfs.ext4"
TAR_PATH="output/images/rootfs.tar.gz"

if [ -f "$EXT4_PATH" ] || [ -f "$TAR_PATH" ]; then
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ARM64 Build completed successfully! (OCI)           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    mkdir -p "$ISO_DIR"
    
    if [ -f "$EXT4_PATH" ]; then
        cp "$EXT4_PATH" "$ISO_DIR/zlag-oracle-arm64.ext4"
        echo -e "${GREEN}  ✓ Artifact: $ISO_DIR/zlag-oracle-arm64.ext4${NC}"
    fi
    
    if [ -f "$TAR_PATH" ]; then
        cp "$TAR_PATH" "$ISO_DIR/zlag-oracle-arm64.tar.gz"
        echo -e "${GREEN}  ✓ Artifact: $ISO_DIR/zlag-oracle-arm64.tar.gz${NC}"
    fi
    
    # Checksums
    cd "$ISO_DIR"
    sha256sum zlag-oracle-arm64.* > checksums.txt 2>/dev/null || shasum -a 256 zlag-oracle-arm64.* > checksums.txt
    echo -e "${GREEN}  ✓ Checksum: $ISO_DIR/checksums.txt${NC}"

else
    # Si estábamos en modo clean, no es un error
    if [ "$1" != "clean" ]; then
        echo -e "\n${RED}[✘] Build failed! Check errors above.${NC}"
        exit 1
    fi
fi