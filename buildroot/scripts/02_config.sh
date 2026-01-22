#!/bin/bash
# scripts/02_config.sh

configure_system() {
    echo -e "${BLUE}[⚙️] Generando archivos de configuración e inyectando ENV...${NC}"
    mkdir -p board/zgate

    # 1. FRAGMENTO DEL KERNEL (Networking + Audio Fix + NFT Fix)
    cat <<EOF > board/zgate/linux.fragment
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

# --- FIREWALL & NAT ---
CONFIG_NETFILTER=y
CONFIG_NETFILTER_ADVANCED=y
CONFIG_NF_CONNTRACK=y
CONFIG_NF_LOG_COMMON=y
CONFIG_NF_TABLES=y
CONFIG_NF_TABLES_INET=y
CONFIG_NF_TABLES_IPV4=y
CONFIG_NF_TABLES_IPV6=y
CONFIG_NFT_CT=y
CONFIG_NFT_LOG=y
CONFIG_NFT_LIMIT=y
CONFIG_NFT_MASQ=y
CONFIG_NFT_NAT=y
CONFIG_NF_NAT=y
CONFIG_NF_NAT_MASQUERADE=y
# Soporte para Gaming (DSCP/TOS)
CONFIG_NFT_TOS=y
CONFIG_NFT_PAYLOAD=y
CONFIG_NFT_EXTHDR=y
CONFIG_NETFILTER_XT_TARGET_DSCP=y

# --- VPN & TUNNELING ---
CONFIG_WIREGUARD=y

# --- REDUNDANCIA ---
CONFIG_BONDING=y
CONFIG_VXLAN=y
EOF

    # 2. CONFIGURACIÓN BUILDROOT
    cat <<EOF > configs/zgate_defconfig
BR2_x86_64=y
BR2_TOOLCHAIN_BUILDROOT=y
BR2_TOOLCHAIN_BUILDROOT_UCLIBC=y
BR2_KERNEL_HEADERS_6_1=y
BR2_TOOLCHAIN_BUILDROOT_WCHAR=y
BR2_TOOLCHAIN_BUILDROOT_CXX=y
BR2_LINUX_KERNEL=y
BR2_LINUX_KERNEL_CUSTOM_VERSION=y
BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="6.1.100"
BR2_LINUX_KERNEL_USE_ARCH_DEFAULT_CONFIG=y
BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="board/zgate/linux.fragment"
BR2_PACKAGE_LIBNFTNL=y
BR2_PACKAGE_NFTABLES=y
BR2_PACKAGE_WIREGUARD_TOOLS=y
BR2_PACKAGE_IPROUTE2=y
BR2_PACKAGE_BASH=y
BR2_TARGET_GENERIC_HOSTNAME="ZGate-Node"
BR2_TARGET_GENERIC_ISSUE="Welcome to ZGate"
BR2_ROOTFS_OVERLAY="board/zgate/rootfs-overlay"
BR2_ROOTFS_POST_BUILD_SCRIPT="board/zgate/post_build.sh"
BR2_TARGET_ROOTFS_CPIO=y
BR2_TARGET_ROOTFS_CPIO_GZIP=y
BR2_TARGET_ROOTFS_ISO9660=y
BR2_TARGET_ROOTFS_ISO9660_BOOT_MENU="board/zgate/menu.cfg"
BR2_TARGET_ROOTFS_ISO9660_HYBRID=y
BR2_TARGET_GRUB2=y
BR2_TARGET_GRUB2_PC=y
BR2_TARGET_GRUB2_BOOT_PARTITION="eltorito"
BR2_TARGET_GRUB2_BUILTIN_CONFIG_PC="board/zgate/grub-pre.cfg"
BR2_TARGET_GRUB2_BUILTIN_MODULES_PC="boot linux ext2 fat part_msdos part_gpt normal biosdisk iso9660 search search_fs_file echo test"
EOF

    # 3. SCRIPTS DE SOPORTE (Inyección de Secretos)
    cat <<EOF > board/zgate/post_build.sh
#!/bin/bash
set -e
TARGET_DIR=\$1
rm -rf \${TARGET_DIR}/var/run
ln -snf ../run \${TARGET_DIR}/var/run
mkdir -p \${TARGET_DIR}/boot/grub \${TARGET_DIR}/usr/bin \${TARGET_DIR}/sbin
cp board/zgate/menu.cfg \${TARGET_DIR}/boot/grub/grub.cfg

# Generar /init
cat <<REQ > \${TARGET_DIR}/init
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
export ZGATE_SECRET="${ZGATE_SECRET}"
export VULTR_API_KEY="${VULTR_API_KEY}"
export MAX_MINUTES="${MAX_MINUTES}"

echo "🔍 Levantando interfaces..."
for iface in /sys/class/net/*; do
    ifname=\$(basename "\$iface")
    if [ "\$ifname" != "lo" ] && [ "\$ifname" != "sit0" ]; then
        /sbin/ip link set \$ifname up
    fi
done

exec /sbin/init
REQ
chmod 755 \${TARGET_DIR}/init

# Permisos del Agente
[ -f "\${TARGET_DIR}/usr/bin/z-gate-agent" ] && chmod +x \${TARGET_DIR}/usr/bin/z-gate-agent
EOF
    chmod +x board/zgate/post_build.sh

    # 4. GRUB CONFIGS
    cat <<EOF > board/zgate/grub-pre.cfg
set root=(cd)
set prefix=(cd)/boot/grub
configfile /boot/grub/grub.cfg
EOF

    cat <<EOF > board/zgate/menu.cfg
set default=0
set timeout=3
menuentry "Z-Gate OS (Prod)" {
    linux /boot/bzImage console=tty0 console=ttyS0,115200 quiet panic=10 clocksource=hpet
    initrd /boot/initrd
}
EOF
}