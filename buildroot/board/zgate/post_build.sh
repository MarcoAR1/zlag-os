#!/bin/bash
set -e
TARGET_DIR=$1
rm -rf ${TARGET_DIR}/var/run
ln -snf ../run ${TARGET_DIR}/var/run
mkdir -p ${TARGET_DIR}/boot/grub ${TARGET_DIR}/usr/bin ${TARGET_DIR}/sbin
cp board/zgate/menu.cfg ${TARGET_DIR}/boot/grub/grub.cfg

# Generar /init
cat <<REQ > ${TARGET_DIR}/init
#!/bin/sh
# Agregamos el PATH aquí para que todo lo que venga después funcione
export PATH=/sbin:/usr/sbin:/bin:/usr/bin

/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mount -t tmpfs tmpfs /run
mkdir -p /run/lock /run/log /tmp
chmod 1777 /tmp

echo "--- 🚀 Z-GATE OS STARTED ---"
export ZGATE_SECRET="zgate-dev-default"
export VULTR_API_KEY=""
export MAX_MINUTES="60"

echo "🔍 Levantando interfaces..."
for iface in /sys/class/net/*; do
    ifname=$(basename "$iface")
    if [ "$ifname" != "lo" ] && [ "$ifname" != "sit0" ]; then
        /sbin/ip link set $ifname up
    fi
done

exec /sbin/init
REQ
chmod 755 ${TARGET_DIR}/init

# Permisos del Agente
[ -f "${TARGET_DIR}/usr/bin/z-gate-agent" ] && chmod +x ${TARGET_DIR}/usr/bin/z-gate-agent
