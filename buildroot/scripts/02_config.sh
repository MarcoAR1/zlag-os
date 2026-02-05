#!/bin/bash
# scripts/02_config.sh

set -euo pipefail

configure_system() {
    echo -e "${BLUE}[⚙️] Generando archivos de configuración e inyectando ENV...${NC}"
    mkdir -p board/zlag
    mkdir -p board/zlag/rootfs-overlay

    # ==========================================================================
    # 1. FRAGMENTO DEL KERNEL (SOPORTE TOTAL: LOGGING + INGRESS + FLOW)
    # ==========================================================================
    cat <<EOF > board/zlag/linux.fragment
# --- BUILD FIX ---
# CONFIG_OBJTOOL is not set
# CONFIG_UNWINDER_ORC is not set
CONFIG_UNWINDER_FRAME_POINTER=y

# --- VIRTUALIZATION ---
CONFIG_HYPERVISOR_GUEST=y
CONFIG_PARAVIRT=y
CONFIG_KVM_GUEST=y
CONFIG_PARAVIRT_SPINLOCKS=y
CONFIG_PCI=y
CONFIG_PCI_MSI=y
CONFIG_NET_VENDOR_INTEL=y
CONFIG_E1000=y
CONFIG_E1000E=y
CONFIG_VIRTIO_MENU=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_NET=y

# --- NETWORKING ---
CONFIG_NET=y
CONFIG_INET=y
CONFIG_IPV6=y
CONFIG_PACKET=y
CONFIG_NET_CORE=y
CONFIG_IP_ADVANCED_ROUTER=y
CONFIG_IP_MULTIPLE_TABLES=y
CONFIG_NET_SCHED=y

# --- FIREWALL CORE (NETFILTER) ---
CONFIG_NETFILTER=y
CONFIG_NETFILTER_ADVANCED=y
CONFIG_NETFILTER_INGRESS=y
CONFIG_NETFILTER_NETLINK_GLUE_CT=y
CONFIG_NF_CONNTRACK=y
CONFIG_NF_LOG_COMMON=y
CONFIG_NETFILTER_XTABLES=y

# --- LOGGING BACKENDS (CRÍTICO: FIX ERROR 'log prefix') ---
CONFIG_NF_LOG_SYSLOG=y
CONFIG_NF_LOG_IPV4=y
CONFIG_NF_LOG_IPV6=y

# --- NFTABLES (FULL SUITE) ---
CONFIG_NF_TABLES=y
CONFIG_NF_TABLES_INET=y
CONFIG_NF_TABLES_IPV4=y
CONFIG_NF_TABLES_IPV6=y
CONFIG_NF_TABLES_ARP=y
CONFIG_NF_TABLES_NETDEV=y
CONFIG_NF_TABLES_BRIDGE=y

# --- NFTABLES MODULES ---
CONFIG_NFT_META=y
CONFIG_NFT_CT=y
CONFIG_NFT_RBTREE=y
CONFIG_NFT_HASH=y
CONFIG_NFT_COUNTER=y
CONFIG_NFT_LOG=y
CONFIG_NFT_LIMIT=y
CONFIG_NFT_MASQ=y
CONFIG_NFT_NAT=y
CONFIG_NFT_TUNNEL=y
CONFIG_NFT_OBJREF=y
CONFIG_NFT_QUOTA=y
CONFIG_NFT_REJECT=y
CONFIG_NFT_REJECT_INET=y
CONFIG_NFT_REJECT_IPV4=y
CONFIG_NFT_REJECT_IPV6=y
CONFIG_NFT_COMPAT=y
CONFIG_NFT_CONNLIMIT=y
CONFIG_NFT_SOCKET=y
CONFIG_NFT_TPROXY=y
CONFIG_NFT_SYNPROXY=y

# --- FLOW OFFLOAD (GAMING ACCEL) ---
CONFIG_NF_FLOW_TABLE=y
CONFIG_NF_FLOW_TABLE_INET=y
CONFIG_NF_FLOW_TABLE_IPV4=y
CONFIG_NF_FLOW_TABLE_IPV6=y
CONFIG_NFT_FLOW_OFFLOAD=y

# --- TRAFFIC CONTROL (QoS & INGRESS) ---
CONFIG_NET_CLS_ACT=y
CONFIG_NET_SCH_INGRESS=y

# --- NAT ---
CONFIG_NF_NAT=y
CONFIG_NF_NAT_MASQUERADE=y

# --- SECURITY ---
CONFIG_SPECULATION_MITIGATIONS=y
CONFIG_MITIGATION_SPECTRE_V2=y
CONFIG_MITIGATION_MELTDOWN=y
CONFIG_MITIGATION_RETBLEED=y
CONFIG_STACKPROTECTOR=y
CONFIG_STACKPROTECTOR_STRONG=y
CONFIG_STRICT_KERNEL_RWX=y
CONFIG_PAGE_TABLE_ISOLATION=y

# --- VPN & TUNNELING ---
CONFIG_WIREGUARD=y

# --- NETWORK PERFORMANCE ---
CONFIG_NET_RX_BUSY_POLL=y
CONFIG_RPS=y
CONFIG_RFS_ACCEL=y
CONFIG_XDP_SOCKETS=y
CONFIG_BPF_SYSCALL=y
CONFIG_BPF_JIT=y
EOF

    # ==========================================================================
    # 2. CONFIGURACIÓN BUILDROOT (zlag_defconfig)
    # ==========================================================================
    cat <<EOF > configs/zlag_defconfig
BR2_x86_64=y
BR2_CCACHE=y
BR2_CCACHE_DIR="/buildroot-src/dl/ccache"
BR2_CCACHE_USE_BASEDIR=y
BR2_JLEVEL=0
BR2_TOOLCHAIN_BUILDROOT=y
BR2_TOOLCHAIN_BUILDROOT_UCLIBC=y
BR2_KERNEL_HEADERS_6_1=y
BR2_TOOLCHAIN_BUILDROOT_WCHAR=y
BR2_TOOLCHAIN_BUILDROOT_CXX=y
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_VERSION=y
BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="6.1.100"
BR2_LINUX_KERNEL_USE_ARCH_DEFAULT_CONFIG=y
BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="board/zlag/linux.fragment"
BR2_LINUX_KERNEL_NEEDS_HOST_LIBELF=n
BR2_LINUX_KERNEL_NEEDS_HOST_OPENSSL=n
BR2_PACKAGE_LIBNFTNL=y
BR2_PACKAGE_NFTABLES=y
BR2_PACKAGE_WIREGUARD_TOOLS=y
BR2_PACKAGE_IPROUTE2=y
BR2_PACKAGE_BASH=y
BR2_PACKAGE_ELFUTILS=y
BR2_PACKAGE_LLVM=y
BR2_PACKAGE_CLANG=y
BR2_TARGET_GENERIC_HOSTNAME="ZLag-Node"
BR2_TARGET_GENERIC_ISSUE="Welcome to ZLag"
BR2_ROOTFS_OVERLAY="board/zlag/rootfs-overlay"
BR2_ROOTFS_POST_BUILD_SCRIPT="board/zlag/post_build.sh"
BR2_TARGET_ROOTFS_CPIO=y
BR2_TARGET_ROOTFS_CPIO_GZIP=y
BR2_TARGET_ROOTFS_SQUASHFS=y
BR2_TARGET_ROOTFS_SQUASHFS4_XZ=y
BR2_TARGET_ROOTFS_SQUASHFS4_XZ_EXTREME=y
BR2_TARGET_ROOTFS_ISO9660=y
BR2_TARGET_ROOTFS_ISO9660_BOOT_MENU="board/zlag/menu.cfg"
BR2_TARGET_ROOTFS_ISO9660_HYBRID=y
BR2_TARGET_GRUB2=y
BR2_TARGET_GRUB2_PC=y
BR2_TARGET_GRUB2_BOOT_PARTITION="eltorito"
BR2_TARGET_GRUB2_BUILTIN_CONFIG_PC="board/zlag/grub-pre.cfg"
BR2_TARGET_GRUB2_BUILTIN_MODULES_PC="boot linux ext2 fat part_msdos part_gpt normal biosdisk iso9660 search search_fs_file echo test configfile"
EOF

    # ==========================================================================
    # 3. SCRIPTS DE SOPORTE (POST-BUILD & INIT)
    # ==========================================================================
    cat <<'EOF' > board/zlag/post_build.sh
#!/bin/bash
set -e
TARGET_DIR=$1

rm -rf ${TARGET_DIR}/var/run
ln -snf ../run ${TARGET_DIR}/var/run
mkdir -p ${TARGET_DIR}/boot/grub ${TARGET_DIR}/usr/bin ${TARGET_DIR}/sbin
cp board/zlag/menu.cfg ${TARGET_DIR}/boot/grub/grub.cfg

# === FIX: Usar busybox ip en lugar de iproute2 ip (evita dep libelf) ===
rm -f ${TARGET_DIR}/sbin/ip 2>/dev/null || true
ln -sf /bin/busybox ${TARGET_DIR}/sbin/ip

# === LIMPIEZA DE INIT ===
echo "🧹 Limpiando scripts init default..."
rm -f ${TARGET_DIR}/etc/init.d/S*

# Generar /init
cat > ${TARGET_DIR}/init << 'INITEOF'
#!/bin/sh
export PATH=/sbin:/usr/sbin:/bin:/usr/bin

/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mount -t tmpfs tmpfs /run
mkdir -p /run/lock /run/log /tmp /usr/share/udhcpc
chmod 1777 /tmp

echo "--- 🚀 Z-Lag OS STARTED ---"
INITEOF

cat >> ${TARGET_DIR}/init <<'INITEOF2'

echo "⚡ Iniciando configuración de red..."

# 1. Loopback
/sbin/ip link set lo up
/sbin/ip addr add 127.0.0.1/8 dev lo 2>/dev/null || true

# 2. CÁLCULO DINÁMICO DE RECURSOS (CPU)
CPU_COUNT=$(grep -c processor /proc/cpuinfo)
LAST_CPU=$((CPU_COUNT - 1))
MASK_DEC=$(( (1 << CPU_COUNT) - 1 ))
MASK_HEX=$(printf "%x" $MASK_DEC)

echo "ℹ️ Hardware detectado: $CPU_COUNT CPUs (Máscara RPS: $MASK_HEX)"

# 3. AUTODETECCIÓN DE INTERFAZ WAN
echo "⏳ Detectando interfaz principal..."
count=0
IFACE=""

# Filtro para ignorar interfaces virtuales
while [ -z "$IFACE" ] && [ $count -lt 50 ]; do
    IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -v -E 'lo|sit|wg|bond|dummy|tun|tap' | head -n 1)
    if [ -z "$IFACE" ]; then
        sleep 0.1
        count=$((count+1))
    fi
done

if [ -n "$IFACE" ]; then
    echo "✅ Interfaz Física Detectada: $IFACE"
    /sbin/ip link set $IFACE up

    # SOLICITAR IP VÍA DHCP
    echo "🌐 Solicitando IP vía DHCP en $IFACE..."
    /sbin/udhcpc -b -i $IFACE -s /usr/share/udhcpc/default.script >/dev/null 2>&1 &

    # === FIX RACE CONDITION: ESPERAR A LA RED ===
    echo "⏳ Esperando concesión DHCP..."
    dhcp_wait=0
    has_ip=0
    while [ $dhcp_wait -lt 100 ]; do # 10 segundos timeout
        if ip route | grep -q "default"; then
            has_ip=1
            break
        fi
        sleep 0.1
        dhcp_wait=$((dhcp_wait+1))
    done

    if [ $has_ip -eq 1 ]; then
        echo "✅ Red Configurada."
        
        # === FIX: PRE-CARGAR TABLAS NFTABLES ===
        # Vital: El agente asume que 'inet filter' existe.
        echo "🛡️ Inicializando firewall base..."
        nft add table inet filter
        nft add chain inet filter input { type filter hook input priority 0 \; policy accept \; }
        nft add chain inet filter forward { type filter hook forward priority 0 \; policy accept \; }
        nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }
        echo "✅ Firewall base listo."
        
        export WAN_IFACE="$IFACE"
    else
        echo "⚠️ Timeout esperando DHCP."
    fi

    # C. OPTIMIZACIONES GAMING (RUNTIME)
    # Activamos Busy Poll en runtime porque el Kernel ya tiene el soporte (CONFIG_NET_RX_BUSY_POLL=y)
    echo 50 > /proc/sys/net/core/busy_poll
    echo 50 > /proc/sys/net/core/busy_read
    echo 300000 > /proc/sys/net/core/netdev_max_backlog
    ethtool -C $IFACE rx-usecs 10 rx-frames 4 2>/dev/null || true
    ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
    ethtool -K $IFACE gro off 2>/dev/null || true
    ethtool -K $IFACE gso off 2>/dev/null || true

    # IRQ Affinity
    echo "⚡ Distribuyendo interrupciones en CPUs 0-$LAST_CPU..."
    for irq in $(grep -E "$IFACE|virtio" /proc/interrupts | cut -d: -f1 | tr -d ' '); do
        echo "0-$LAST_CPU" > /proc/irq/$irq/smp_affinity_list 2>/dev/null || true
    done

    # RPS
    if [ -d "/sys/class/net/$IFACE/queues" ]; then
        for rps in /sys/class/net/$IFACE/queues/rx-*/rps_cpus; do
            [ -f "$rps" ] && echo "$MASK_HEX" > "$rps" 2>/dev/null || true
        done
        echo "✓ RPS activado en $IFACE usando máscara $MASK_HEX"
    fi
else
    echo "⚠️ ADVERTENCIA: No se detectó interfaz física."
fi

# Levantando otras interfaces
for iface in /sys/class/net/*; do
    ifname=$(basename "$iface")
    if [ "$ifname" != "lo" ] && [ "$ifname" != "sit0" ] && [ "$ifname" != "$IFACE" ]; then
        /sbin/ip link set $ifname up
    fi
done

# === TEST NFTABLES KERNEL SUPPORT ===
echo "🧪 Testeando soporte Kernel NFTables..."
if nft list ruleset > /dev/null 2>&1; then
    echo "✅ Kernel NFTables: OK"
else
    echo "❌ Kernel NFTables: FALLO"
fi

# === INICIO DEL AGENTE Z-Lag ===
echo "🚀 Iniciando Z-Lag Agent..."
if [ -f "/usr/bin/zlag-agent" ]; then
    /usr/bin/zlag-agent &
else
    echo "❌ Error: Binario zlag-agent no encontrado"
fi

exec /sbin/init
INITEOF2

chmod 755 ${TARGET_DIR}/init

# SCRIPT DHCP
mkdir -p ${TARGET_DIR}/usr/share/udhcpc
cat > ${TARGET_DIR}/usr/share/udhcpc/default.script << 'DHCPEOF'
#!/bin/sh
[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1
case "$1" in
    deconfig)
        /sbin/ip addr flush dev $interface
        ;;
    bound|renew)
        /sbin/ip addr add $ip/$mask dev $interface
        if [ -n "$router" ]; then
             while /sbin/ip route del default 2>/dev/null ; do :; done
             for i in $router ; do
                  /sbin/ip route add default via $i dev $interface
             done
        fi
        if [ -n "$dns" ]; then
             echo -n > /etc/resolv.conf
             for i in $dns ; do
                  echo nameserver $i >> /etc/resolv.conf
             done
        fi
        ;;
esac
exit 0
DHCPEOF
chmod +x ${TARGET_DIR}/usr/share/udhcpc/default.script

# Permisos
[ -f "${TARGET_DIR}/usr/bin/zlag-agent" ] && chmod +x ${TARGET_DIR}/usr/bin/zlag-agent
echo "✓ Post-build completado: Full Kernel + Pre-Heat NFT"
EOF
    chmod +x board/zlag/post_build.sh

    # ==========================================================================
    # 4. GRUB CONFIGS
    # ==========================================================================
    cat <<EOF > board/zlag/grub-pre.cfg
set root=(cd)
set prefix=(cd)/boot/grub
configfile /boot/grub/grub.cfg
EOF

    cat <<EOF > board/zlag/menu.cfg
set default=0
set timeout=3
menuentry "Z-Lag OS (Prod)" {
    linux /boot/bzImage console=tty0 console=ttyS0,115200 quiet panic=10 clocksource=hpet
    initrd /boot/initrd
}
EOF
}