#!/bin/bash
# scripts/00_env.sh

set -euo pipefail

# Configurar TERM para entornos no-interactivos (GitHub Actions, Docker)
export TERM=${TERM:-linux}

# --- RUTAS ---
export ISO_PATH="output/images/rootfs.iso9660"
export KERNEL_BUILD_DIR="output/build/linux-6.1.100"
export AGENT_SRC_DIR="../zlag/agent"

# --- BUILD OPTIMIZATION ---
# JOBS: cores + 2 para I/O overlap (GitHub Actions: 4 cores → 6 jobs)
export JOBS=$(( $(nproc) + 2 ))

# --- COLORES ---
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Limpieza de PATH para WSL
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/mnt/' | tr '\n' ':' | sed 's/:$//')