#!/bin/bash
# scripts/00_env.sh
# ==============================================================================
# 🌍 ZLAG ENVIRONMENT VARIABLES
# ==============================================================================

set -euo pipefail

# Configurar TERM para entornos no-interactivos (GitHub Actions, Docker)
export TERM=${TERM:-linux}

# ==============================================================================
# 📂 RUTAS CRÍTICAS
# ==============================================================================
# Directorio base de salida de Buildroot
export OUTPUT_DIR="output"

# Ruta esperada de la ISO cruda (antes de renombrarla)
export ISO_PATH="${OUTPUT_DIR}/images/rootfs.iso9660"

# ==============================================================================
# ⚙️ OPTIMIZACIÓN DE BUILD
# ==============================================================================
# Cálculo inteligente de JOBS para Make
# Regla general: Nro Cores + 2 (para aprovechar tiempos de I/O de disco)
if [ -z "${JOBS:-}" ]; then
    if command -v nproc >/dev/null; then
        export JOBS=$(( $(nproc) + 2 ))
    else
        export JOBS=2
    fi
fi

# ==============================================================================
# 🎨 PALETA DE COLORES (ANSI)
# ==============================================================================
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# ==============================================================================
# 🛠️ UTILIDADES
# ==============================================================================
# Limpieza de PATH para usuarios de WSL (Windows Subsystem for Linux)
# Evita que espacios en rutas de Windows rompan scripts de Linux
if grep -q "Microsoft" /proc/version 2>/dev/null || grep -q "WSL" /proc/version 2>/dev/null; then
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/mnt/' | tr '\n' ':' | sed 's/:$//')
fi