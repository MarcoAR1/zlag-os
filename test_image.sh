#!/bin/bash
# Verificar contenido de las imágenes

echo "=== Verificando imagen x86_64 ==="
docker run --rm zlag-build:x86_64 sh -c '
echo "Kernel:"
ls -lh /buildroot-src/output/images/bzImage

echo ""
echo "ISO:"
ls -lh /buildroot-src/output/images/rootfs.iso9660

echo ""
echo "Zlag Agent en imagen:"
ls -la /buildroot-src/output/target/usr/bin/zlag-agent
file /buildroot-src/output/target/usr/bin/zlag-agent

echo ""
echo "Init system:"
ls -la /buildroot-src/output/target/sbin/init 2>/dev/null || echo "init symlink"
ls -la /buildroot-src/output/target/bin/busybox
'

echo ""
echo "=== Verificando imagen ARM64 ==="
docker run --rm zlag-build:arm64 sh -c '
echo "Kernel Image:"
ls -lh /buildroot-src/output/images/Image

echo ""
echo "Rootfs ext4:"
ls -lh /buildroot-src/output/images/rootfs.ext4

echo ""
echo "Zlag Agent:"
ls -la /buildroot-src/output/target/usr/bin/zlag-agent
file /buildroot-src/output/target/usr/bin/zlag-agent
'
