#!/bin/bash
# ==============================================================================
# 🚀 ZLAG OS - Incremental ISO Build (Reuses Cached Kernel)
# ==============================================================================
# This script runs INSIDE the existing cached Docker image to regenerate
# only the rootfs/ISO without recompiling the kernel.
set -e

echo "==================================================="
echo "🔄 ZLAG OS Incremental Build (Kernel Cache Mode)"
echo "==================================================="

# Navigate to buildroot
cd /buildroot-src

# Source environment
source scripts/00_env.sh

# Regenerate configuration files with new changes (wget + new agent URL)
echo "[1/4] Regenerando configuración con nuevos paquetes..."
source scripts/02_config.sh
configure_system

# Apply new defconfig
echo "[2/4] Aplicando zlag_defconfig..."
make zlag_defconfig

# Force rootfs regeneration (this is fast compared to kernel)
echo "[3/4] Forzando regeneración de rootfs..."
rm -f output/images/rootfs.* 2>/dev/null || true
rm -f output/images/bzImage 2>/dev/null || true

# Build with 4 cores (limited for TDP)
echo "[4/4] Compilando (4 cores)..."
echo "    Esto debería ser rápido si el kernel ya está cacheado..."
make -j4

# Copy ISO to accessible location
echo ""
echo "=== ISO Generada ==="
if [ -f "output/images/rootfs.iso9660" ]; then
    cp output/images/rootfs.iso9660 /output/zlag-vultr-x86_64.iso
    echo "✅ ISO copiada a /output/zlag-vultr-x86_64.iso"
    ls -lh /output/zlag-vultr-x86_64.iso
else
    echo "❌ No se generó la ISO"
    ls -la output/images/
    exit 1
fi

echo ""
echo "✅ Build incremental completado!"
