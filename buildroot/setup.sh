#!/bin/bash
# ==============================================================================
#  🛡️ Z-GATE CORE ORCHESTRATOR v34.0 (MODULAR) - Vultr x86_64
# ==============================================================================

set -euo pipefail

# Configurar TERM para entornos no-interactivos (GitHub Actions)
export TERM=${TERM:-linux}

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
ISO_DIR="$SCRIPT_DIR/isos/vultr-x86_64"

# Importar Módulos
source scripts/00_env.sh
source scripts/01_deps.sh
source scripts/02_config.sh
source scripts/03_agent.sh

# Cargar Secretos
load_secrets

# Función de Cabecera
header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${CYAN}       🛡️  Z-GATE CORE | ORCHESTRATOR v34.0       ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "Modo: ${YELLOW}$1${NC} | Jobs: ${YELLOW}$JOBS${NC}"
    echo -e "Secret Injection: ${GREEN}ACTIVE${NC}"
    echo -e "Audio Fix: ${GREEN}ACTIVE${NC}"
    echo -e "----------------------------------------------------"
}

# Lógica de Make
run_full_build() {
    echo -e "${RED}[☢️] LIMPIEZA NUCLEAR DE KERNEL...${NC}"
    rm -rf output/build/linux-6.1.100 
    rm -f output/build/.fragments_list # Borrar la lista de fragmentos aplicados
    rm -f output/images/bzImage

    echo -e "${BLUE}[🛠️] Configurando Buildroot...${NC}"
    make zgate_defconfig
    
    echo -e "${BLUE}[🔨] Compilando (10-15 min)...${NC}"
    make -j$JOBS
}

run_update() {
    echo -e "${YELLOW}[⚡] Actualización Rápida...${NC}"
    configure_system # Regenerar configs por si cambiaron secretos o kernel
    
    # Asegurar PATH limpio antes de make
    echo "Cleaned PATH for make: $PATH"
    
    make zgate_defconfig
    make -j$JOBS
}

# --- CONTROLADOR PRINCIPAL ---

if [ "$1" == "build" ]; then
    header "FULL BUILD"
    check_dependencies
    configure_system
    
    # Solo compilar agent si NO fue compilado externamente por build.sh
    if [ ! -f "board/zgate/rootfs-overlay/usr/bin/z-gate-agent" ]; then
        build_agent
    else
        echo -e "${BLUE}[📦] Agent x86_64 ya compilado externamente, omitiendo...${NC}"
    fi
    
    run_full_build

elif [ "$1" == "update" ]; then
    header "UPDATE"
    
    # Solo compilar agent si NO fue compilado externamente por build.sh
    if [ ! -f "board/zgate/rootfs-overlay/usr/bin/z-gate-agent" ]; then
        build_agent
    else
        echo -e "${BLUE}[📦] Agent x86_64 ya compilado externamente, omitiendo...${NC}"
    fi
    
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

if [ -f "$ISO_PATH" ]; then
    echo -e "${GREEN}[✔] ISO GENERADA: $ISO_PATH ($(du -h $ISO_PATH | cut -f1))${NC}"
    
    # Organizar ISOs para Brain
    echo -e "${YELLOW}Organizing ISOs for Brain deployment...${NC}"
    mkdir -p "$ISO_DIR"
    
    # Copiar ISO al directorio de Vultr
    cp "$ISO_PATH" "$ISO_DIR/zgate-vultr-x86_64.iso"
    echo -e "${GREEN}✓ Copied: $ISO_DIR/zgate-vultr-x86_64.iso${NC}"
    
    # Generar SHA256 para Brain
    cd "$ISO_DIR"
    sha256sum zgate-vultr-x86_64.iso > checksums.txt 2>/dev/null || shasum -a 256 zgate-vultr-x86_64.iso > checksums.txt
    echo -e "${GREEN}✓ Generated: $ISO_DIR/checksums.txt${NC}"
    
    echo -e "\n${GREEN}ISOs ready for Brain at:${NC}"
    ls -lh "$ISO_DIR"
else
    echo -e "${RED}[✘] Error: No se generó la ISO.${NC}"
    exit 1
fi