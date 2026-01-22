#!/bin/bash
# ==============================================================================
#  🛡️ Z-GATE CORE ORCHESTRATOR v34.0 (MODULAR) - Oracle Cloud ARM64
# ==============================================================================

set -e

# ============================================================================
# PATH SANITIZATION (Windows/macOS compatibility)
# ============================================================================
# Buildroot no tolera espacios en PATH. Limpiar INMEDIATAMENTE.
clean_path() {
    local NEW_PATH=""
    IFS=':' read -ra PATHS <<< "$PATH"
    for p in "${PATHS[@]}"; do
        # Solo agregar si no tiene espacios, tabs o newlines
        if [[ ! "$p" =~ [[:space:]] ]]; then
            if [ -z "$NEW_PATH" ]; then
                NEW_PATH="$p"
            else
                NEW_PATH="$NEW_PATH:$p"
            fi
        fi
    done
    
    # Si quedó vacío o muy corto, asegurar rutas esenciales
    if [ -z "$NEW_PATH" ] || [ $(echo "$NEW_PATH" | tr ':' '\n' | wc -l) -lt 3 ]; then
        NEW_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    fi
    
    export PATH="$NEW_PATH"
}

# Limpiar PATH ANTES de todo (incluyendo imports)
clean_path

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output_arm64"
ISO_DIR="$SCRIPT_DIR/isos/oracle-arm64"

# Importar Módulos
source scripts/00_env.sh
source scripts/01_deps.sh
source scripts/02_config_arm.sh
source scripts/03_agent_arm.sh

# Cargar Secretos
load_secrets

# Función de Cabecera
header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${CYAN}    🛡️  Z-GATE ARM64 | ORCHESTRATOR v34.0 (OCI)    ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "Modo: ${YELLOW}$1${NC} | Jobs: ${YELLOW}$JOBS${NC}"
    echo -e "Architecture: ${YELLOW}ARM64 (aarch64)${NC}"
    echo -e "Target: ${YELLOW}Oracle Cloud Ampere A1${NC}"
    echo -e "Secret Injection: ${GREEN}ACTIVE${NC}"
    echo -e "----------------------------------------------------"
}

# Lógica de Make
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
    configure_system_arm # Regenerar configs
    make O=$OUTPUT_DIR zgate_arm64_defconfig
    make O=$OUTPUT_DIR -j$JOBS
}

# --- CONTROLADOR PRINCIPAL ---

if [ "$1" == "build" ]; then
    header "FULL BUILD"
    check_dependencies
    configure_system_arm
    
    # Solo compilar agent si NO fue compilado externamente por build.sh
    if [ ! -f "board/zgate/rootfs-overlay/usr/bin/z-gate-agent" ]; then
        build_agent_arm
    else
        echo -e "${BLUE}[📦] Agent ARM64 ya compilado externamente, omitiendo...${NC}"
    fi
    
    run_full_build

elif [ "$1" == "update" ]; then
    header "UPDATE"
    
    # Solo compilar agent si NO fue compilado externamente por build.sh
    if [ ! -f "board/zgate/rootfs-overlay/usr/bin/z-gate-agent" ]; then
        build_agent_arm
    else
        echo -e "${BLUE}[📦] Agent ARM64 ya compilado externamente, omitiendo...${NC}"
    fi
    
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
    
    # Copiar archivos al directorio de Oracle
    if [ -f "$EXT4_PATH" ]; then
        cp "$EXT4_PATH" "$ISO_DIR/zgate-oracle-arm64.ext4"
        echo -e "${GREEN}  ✓ Copied: $ISO_DIR/zgate-oracle-arm64.ext4 ($(du -h $ISO_DIR/zgate-oracle-arm64.ext4 | cut -f1))${NC}"
    fi
    
    if [ -f "$TAR_PATH" ]; then
        cp "$TAR_PATH" "$ISO_DIR/zgate-oracle-arm64.tar.gz"
        echo -e "${GREEN}  ✓ Copied: $ISO_DIR/zgate-oracle-arm64.tar.gz ($(du -h $ISO_DIR/zgate-oracle-arm64.tar.gz | cut -f1))${NC}"
    fi
    
    # Generar SHA256 para Brain
    cd "$ISO_DIR"
    sha256sum zgate-oracle-arm64.* > checksums.txt 2>/dev/null || shasum -a 256 zgate-oracle-arm64.* > checksums.txt
    echo -e "${GREEN}  ✓ Generated: $ISO_DIR/checksums.txt${NC}"
    
    echo -e "\n${GREEN}ISOs ready for Brain at:${NC}"
    ls -lh "$ISO_DIR"
    
    echo -e "\n${BLUE}Next steps:${NC}"
    echo -e "${YELLOW}  1.${NC} Brain will upload from: $ISO_DIR"
    echo -e "${YELLOW}  2.${NC} Create Oracle Compute Instance (Ampere A1)"
    echo -e "${YELLOW}  3.${NC} Import custom image from Object Storage"
    echo -e "${YELLOW}  4.${NC} Deploy and test!"
else
    echo -e "\n${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           Build failed! Check errors above.              ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi

exit 0

