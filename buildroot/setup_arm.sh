#!/bin/bash
# ==============================================================================
#  🛡️ Z-GATE CORE ORCHESTRATOR v34.0 (MODULAR) - Oracle Cloud ARM64
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
OUTPUT_DIR="$SCRIPT_DIR/output_arm64"
ISO_DIR="$SCRIPT_DIR/isos/oracle-arm64"

# Importar Módulos
source scripts/00_env.sh
source scripts/01_deps.sh
# NOTA: Asegúrate de que 02_config_arm.sh exista y tenga la función configure_system_arm
source scripts/02_config_arm.sh 
source scripts/03_agent_install.sh # <--- CORREGIDO: Usamos el instalador unificado

# Función de Cabecera
header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${CYAN}    🛡️  Z-GATE ARM64 | ORCHESTRATOR v34.0 (OCI)    ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "Modo: ${YELLOW}$1${NC} | Jobs: ${YELLOW}$JOBS${NC}"
    echo -e "Architecture: ${YELLOW}ARM64 (aarch64)${NC}"
    echo -e "Target: ${YELLOW}Oracle Cloud Ampere A1${NC}"
    echo -e "----------------------------------------------------"
}

# Lógica de Make (ARM64 usa O=... para separar output)
run_full_build() {
    echo -e "${RED}[☢️] LIMPIEZA NUCLEAR DE KERNEL ARM64...${NC}"
    rm -rf $OUTPUT_DIR/build/linux-*
    rm -f $OUTPUT_DIR/build/.fragments_list
    rm -f $OUTPUT_DIR/images/Image

    echo -e "${BLUE}[🛠️] Configurando Buildroot ARM64...${NC}"
    make O=$OUTPUT_DIR zgate_arm64_defconfig
    
    echo -e "${BLUE}[🔨] Compilando (30-60 min primera vez)...${NC}"
    make O=$OUTPUT_DIR -j$JOBS
}

run_update() {
    echo -e "${YELLOW}[⚡] Actualización Rápida ARM64...${NC}"
    configure_system_arm 
    
    if [ -d "$OUTPUT_DIR" ] && [ -f "$OUTPUT_DIR/.config" ]; then
        echo -e "${GREEN}[📦] Cache detectado, recompilando cambios...${NC}"
        make O=$OUTPUT_DIR zgate_arm64_defconfig
        make O=$OUTPUT_DIR -j$JOBS
    else
        echo -e "${YELLOW}[🔨] No cache found, running full build...${NC}"
        make O=$OUTPUT_DIR zgate_arm64_defconfig
        make O=$OUTPUT_DIR -j$JOBS
    fi
}

# --- CONTROLADOR PRINCIPAL ---

if [ "$1" == "build" ]; then
    header "FULL BUILD"
    check_dependencies
    configure_system_arm
    
    # INSTALACIÓN DEL AGENTE (ARM64)
    # Copia z-gate-agent-arm64 -> board/zgate/.../usr/bin/z-gate-agent
    install_prebuilt_agent "arm64"
    
    run_full_build

elif [ "$1" == "update" ]; then
    header "UPDATE"
    
    # INSTALACIÓN DEL AGENTE (ARM64)
    # Siempre ejecutamos para tener el binario más nuevo
    install_prebuilt_agent "arm64"
    
    run_update

elif [ "$1" == "clean" ]; then
    header "LIMPIEZA"
    echo -e "${RED}Borrando $OUTPUT_DIR...${NC}"
    rm -rf $OUTPUT_DIR
    echo -e "${GREEN}Listo.${NC}"
    exit 0

else
    echo -e "${RED}Uso: ./setup_arm.sh {build|update|clean}${NC}"
    exit 1
fi

# Verificar outputs y organizar ISOs
EXT4_PATH="$OUTPUT_DIR/images/rootfs.ext4"
TAR_PATH="$OUTPUT_DIR/images/rootfs.tar.gz"

if [ -f "$EXT4_PATH" ] || [ -f "$TAR_PATH" ]; then
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ARM64 Build completed successfully! (OCI)           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BLUE}Output files:${NC}"
    ls -lh $OUTPUT_DIR/images/
    
    # Organizar ISOs para Brain
    echo -e "\n${YELLOW}[📦] Organizing ISOs for Brain deployment...${NC}"
    mkdir -p "$ISO_DIR"
    
    if [ -f "$EXT4_PATH" ]; then
        cp "$EXT4_PATH" "$ISO_DIR/zgate-oracle-arm64.ext4"
        echo -e "${GREEN}  ✓ Copied: $ISO_DIR/zgate-oracle-arm64.ext4 ($(du -h $ISO_DIR/zgate-oracle-arm64.ext4 | cut -f1))${NC}"
    fi
    
    if [ -f "$TAR_PATH" ]; then
        cp "$TAR_PATH" "$ISO_DIR/zgate-oracle-arm64.tar.gz"
        echo -e "${GREEN}  ✓ Copied: $ISO_DIR/zgate-oracle-arm64.tar.gz ($(du -h $ISO_DIR/zgate-oracle-arm64.tar.gz | cut -f1))${NC}"
    fi
    
    # Generar SHA256
    cd "$ISO_DIR"
    sha256sum zgate-oracle-arm64.* > checksums.txt 2>/dev/null || shasum -a 256 zgate-oracle-arm64.* > checksums.txt
    echo -e "${GREEN}  ✓ Generated: $ISO_DIR/checksums.txt${NC}"
    
    echo -e "\n${GREEN}ISOs ready for Brain at:${NC}"
    ls -lh "$ISO_DIR"
else
    echo -e "\n${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           Build failed! Check errors above.               ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi

exit 0