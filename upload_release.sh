#!/bin/bash
set -e

cd /mnt/c/Users/Marco/Documents/projects/zlag-os

VERSION=$(date +%Y%m%d-%H%M)
TAG="iso-$VERSION"

echo "📦 Calculando checksums..."
X86_SUM=$(sha256sum output/vultr/zlag-vultr.iso | cut -d' ' -f1)
ARM_SUM=$(sha256sum output/oracle/zlag-oracle.ext4 | cut -d' ' -f1)

echo "📤 Creando release: $TAG"
echo "  x86_64: $X86_SUM"
echo "  ARM64: $ARM_SUM"

gh release create "$TAG" \
    output/vultr/zlag-vultr.iso \
    output/oracle/zlag-oracle.ext4 \
    --repo marcoar1/zlag-os \
    --title "Z-Lag OS Production $VERSION" \
    --notes "📦 Release generado localmente.

**Checksums:**
- x86_64: $X86_SUM
- ARM64: $ARM_SUM"

echo "✅ Release publicado exitosamente: $TAG"
