#!/bin/bash
# ==============================================================================
# 🛡️ ZLAG CORE ORCHESTRATOR v1.0 - Vultr x86_64
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
# Ruta de salida estandarizada para Zlag/Vultr
ISO_DIR="$SCRIPT_DIR/isos/vultr-x86_64"
# Nombre esperado de la ISO generado por Buildroot
ISO_PATH="$SCRIPT_DIR/output/images/rootfs.iso9660"

# Importar Módulos
source scripts/00_env.sh
source scripts/01_deps.sh
source scripts/02_config.sh

# Manejo seguro del script de instalación de agente
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
    echo -e "${CYAN}      🛡️  ZLAG OS CORE | ORCHESTRATOR x86_64       ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "Modo: ${YELLOW}$1${NC} | Jobs: ${YELLOW}$JOBS${NC}"
    echo -e "Arch: ${GREEN}x86_64 (Vultr)${NC}"
    echo -e "----------------------------------------------------"
}

# Lógica de Make (Full Build)
run_full_build() {
    echo -e "${RED}[☢️] LIMPIEZA NUCLEAR DE KERNEL...${NC}"
    rm -rf output/build/linux-* rm -f output/build/.fragments_list
    rm -f output/images/bzImage

    echo -e "${BLUE}[🛠️] Configurando Buildroot (Zlag Profile)...${NC}"
    make zlag_defconfig
    
    echo -e "${BLUE}[🔨] Compilando Kernel y Toolchain (Esto puede tardar)...${NC}"
    make -j$JOBS
}

# Lógica de Update (Ensamblaje Rápido)
run_update() {
    echo -e "${YELLOW}[⚡] Actualización Rápida (RootFS Rebuild)...${NC}"
    configure_system 
    
    # Truco para forzar regeneración de ISO sin recompilar todo
    rm -f output/images/rootfs.iso9660
    
    if [ -d "output" ] && [ -f "output/.config" ]; then
        echo -e "${GREEN}[📦] Cache detectado, ensamblando ISO...${NC}"
        make zlag_defconfig
        make -j$JOBS
    else
        echo -e "${YELLOW}[🔨] No cache found, running full build fallback...${NC}"
        make zlag_defconfig
        make -j$JOBS
    fi
}

# --- CONTROLADOR PRINCIPAL ---

if [ "$1" == "build" ]; then
    header "FULL BUILD"
    check_dependencies
    configure_system
    
    # INSTALACIÓN DEL AGENTE (OPCIONAL EN BUILD)
    # Si estamos creando la imagen base de Docker, el binario no existe aún.
    # No queremos que falle el build del Kernel por falta del agente.
    if [ -f "bin/z-lag-agent-x86_64" ]; then
        install_prebuilt_agent "x86_64"
    else
        echo -e "${YELLOW}[!] Agente binario no encontrado. Continuando solo con compilación de Kernel.${NC}"
    fi
    
    run_full_build

elif [ "$1" == "update" ]; then
    header "UPDATE"
    
    # INSTALACIÓN DEL AGENTE (MANDATORIA EN UPDATE)
    # Si estamos haciendo un update, ES para meter el agente nuevo.
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

# ============================================================================
# GESTIÓN DE ARTEFACTOS
# ============================================================================
# Solo intentamos mover la ISO si realmente se generó
if [ -f "$ISO_PATH" ]; then
    FINAL_NAME="zlag-vultr-x86_64.iso"
    
    echo -e "${GREEN}[✔] BUILD COMPLETO.${NC}"
    echo -e "${YELLOW}Organizing ISO for deployment...${NC}"
    
    mkdir -p "$ISO_DIR"
    cp "$ISO_PATH" "$ISO_DIR/$FINAL_NAME"
    
    echo -e "${GREEN}✓ Artifact: $ISO_DIR/$FINAL_NAME${NC}"
    echo -e "  Size: $(du -h "$ISO_DIR/$FINAL_NAME" | cut -f1)"
    
    # Generar Checksum
    cd "$ISO_DIR"
    sha256sum "$FINAL_NAME" > checksums.txt 2>/dev/null || shasum -a 256 "$FINAL_NAME" > checksums.txt
    echo -e "${GREEN}✓ Checksum: $ISO_DIR/checksums.txt${NC}"
    
else
    # Si estábamos en modo clean, no es un error
    if [ "$1" != "clean" ]; then
        echo -e "${RED}[✘] Error Crítico: No se generó la ISO en $ISO_PATH.${NC}"
        echo -e "${RED}    Revisa los logs anteriores.${NC}"
        exit 1
    fi
fi