#!/bin/bash
# scripts/02_config_arm.sh - ARM64 Configuration Module

set -euo pipefail

configure_system_arm() {
    echo -e "${BLUE}[⚙️] Generando configuración ARM64 para Oracle Cloud...${NC}"
    mkdir -p board/zgate

    # 1. CREAR CONFIGURACIÓN ARM64 DESDE BASE X86_64
    if [ -f "configs/zgate_defconfig" ]; then
        echo -e "${YELLOW}  → Copiando configuración base...${NC}"
        cp configs/zgate_defconfig configs/zgate_arm64_defconfig
        
        # CRÍTICO: Eliminar configuración x86_64 y reemplazar por ARM64
        echo -e "${YELLOW}  → Eliminando configuraciones x86_64...${NC}"
        
        # Eliminar línea BR2_x86_64=y
        sed -i.bak '/^BR2_x86_64=y/d' configs/zgate_arm64_defconfig
        
        # Eliminar configuraciones de GRUB PC (incompatibles con ARM64)
        sed -i.bak '/^BR2_TARGET_GRUB2_PC=y/d' configs/zgate_arm64_defconfig
        sed -i.bak '/^BR2_TARGET_GRUB2_BOOT_PARTITION=/d' configs/zgate_arm64_defconfig
        sed -i.bak '/^BR2_TARGET_GRUB2_BUILTIN_CONFIG_PC=/d' configs/zgate_arm64_defconfig
        sed -i.bak '/^BR2_TARGET_GRUB2_BUILTIN_MODULES_PC=/d' configs/zgate_arm64_defconfig
        
        # Eliminar ISO9660 (no compatible con ARM64 para Oracle Cloud)
        sed -i.bak '/^BR2_TARGET_ROOTFS_ISO9660/d' configs/zgate_arm64_defconfig
        
        echo -e "${YELLOW}  → Añadiendo configuraciones ARM64...${NC}"
        # Modificar para ARM64 - INSERTAR AL INICIO
        sed -i.bak '1i\
# ============================================================================\
# ARM64 (aarch64) Architecture Configuration for Oracle Cloud\
# ============================================================================\
BR2_aarch64=y\
BR2_cortex_a72=y
' configs/zgate_arm64_defconfig
        
        # Añadir configuraciones específicas ARM64 al final
        cat >> configs/zgate_arm64_defconfig << 'EOF'

# ============================================================================
# ARM64-Specific Toolchain and Kernel
# ============================================================================

# Kernel configuration
BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="board/zgate/linux_arm64.config"

# Post-build script ARM64
BR2_ROOTFS_POST_BUILD_SCRIPT="board/zgate/post_build_arm64.sh"

# --- COMPRESSION (Rootfs size reduction: 50MB → 35MB) ---
BR2_TARGET_ROOTFS_SQUASHFS=y
BR2_TARGET_ROOTFS_SQUASHFS4_XZ=y
BR2_TARGET_ROOTFS_SQUASHFS4_XZ_EXTREME=y

# Target filesystem for Oracle Cloud (EXT4 + TAR.GZ)
BR2_TARGET_ROOTFS_EXT2=y
BR2_TARGET_ROOTFS_EXT2_4=y
BR2_TARGET_ROOTFS_TAR_GZIP=y

# Boot configuration for Oracle Cloud (UEFI ARM64)
BR2_TARGET_GRUB2_ARM64_EFI=y
EOF

        # Cleanup backup files
        rm -f configs/zgate_arm64_defconfig.bak

        echo -e "${GREEN}  ✓ ARM64 config created: configs/zgate_arm64_defconfig${NC}"
        echo -e "${BLUE}    - Removed x86_64 architecture${NC}"
        echo -e "${BLUE}    - Added ARM64 (aarch64) cortex-a72${NC}"
        echo -e "${BLUE}    - Configured for Oracle Cloud Ampere A1${NC}"
    else
        echo -e "${RED}ERROR: configs/zgate_defconfig not found${NC}"
        exit 1
    fi

    # 2. CONFIGURACIÓN DE KERNEL ARM64
    echo -e "${YELLOW}  → Generando linux_arm64.config...${NC}"
    cat > board/zgate/linux_arm64.config << 'EOF'
# Linux Kernel Configuration for ARM64 (Oracle Cloud Ampere A1)

CONFIG_ARM64=y
CONFIG_64BIT=y

# --- BUILD FIX: Disable objtool (not needed for ARM64) ---
# CONFIG_OBJTOOL is not set
# CONFIG_UNWINDER_ORC is not set
CONFIG_UNWINDER_FRAME_POINTER=y

# Oracle Cloud Virtual Machine
CONFIG_ARCH_VIRT=y
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_NET=y
CONFIG_VIRTIO_BLK=y

# --- NETWORKING ---
CONFIG_NET=y
CONFIG_INET=y
CONFIG_IPV6=y
CONFIG_PACKET=y
CONFIG_NET_CORE=y
CONFIG_IP_ADVANCED_ROUTER=y
CONFIG_IP_MULTIPLE_TABLES=y
CONFIG_NETDEVICES=y

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

# --- SECURITY HARDENING (Minimal) ---
# Protección cloud multi-tenant (Spectre/Meltdown)
CONFIG_SPECULATION_MITIGATIONS=y
CONFIG_MITIGATION_SPECTRE_V2=y
CONFIG_MITIGATION_MELTDOWN=y
CONFIG_MITIGATION_RETBLEED=y
# Stack overflow protection
CONFIG_STACKPROTECTOR=y
CONFIG_STACKPROTECTOR_STRONG=y
# Memory protection básica
CONFIG_STRICT_KERNEL_RWX=y
CONFIG_PAGE_TABLE_ISOLATION=y

# --- WIREGUARD ---
CONFIG_WIREGUARD=m

# --- NETWORK PERFORMANCE (Gaming: ultra-low latency) ---
CONFIG_NET_RX_BUSY_POLL=y
CONFIG_RPS=y
CONFIG_RFS_ACCEL=y

# --- XDP & eBPF (Gaming: kernel bypass, -2-5ms latency) ---
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_BPF_JIT=y
CONFIG_BPF_JIT_ALWAYS_ON=y
CONFIG_XDP_SOCKETS=y
CONFIG_BPF_EVENTS=y
# Debugging (development only)
CONFIG_BPF_JIT_DISASM=y

# --- AUDIO FIX (Oracle Cloud kernel panic workaround) ---
# CONFIG_SOUND is not set
# CONFIG_SND is not set

# --- FILESYSTEM SUPPORT ---
CONFIG_EXT4_FS=y
CONFIG_TMPFS=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y

# --- COMPRESSION ---
CONFIG_KERNEL_GZIP=y
EOF
    echo -e "${GREEN}  ✓ linux_arm64.config creado${NC}"

    # 3. POST-BUILD SCRIPT ARM64
    echo -e "${YELLOW}  → Generando post_build_arm64.sh...${NC}"
    cat > board/zgate/post_build_arm64.sh << 'POSTEOF'
#!/bin/bash
# Post-build script for ARM64 (Oracle Cloud)

TARGET_DIR=$1
BOARD_DIR=$(dirname $0)

echo "Z-Gate ARM64 Post-Build Script"

# Cargar variables de entorno desde .secrets
if [ -f "$BOARD_DIR/../../.secrets" ]; then
    source "$BOARD_DIR/../../.secrets"
    echo "✓ Loaded secrets from .secrets"
else
    echo "⚠ Warning: .secrets file not found"
fi

# Generar /init script con secrets
cat > $TARGET_DIR/init << 'INITEOF'
#!/bin/sh

# Mount virtual filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
INITEOF

# Inyectar secrets
echo "export ZGATE_SECRET=\"${ZGATE_SECRET:-zgate-dev-default}\"" >> $TARGET_DIR/init

# Continuar /init script
cat >> $TARGET_DIR/init << 'INITEOF'

# Network setup
ip link set lo up
ip link set eth0 up
udhcpc -i eth0

# Export environment variables
export PATH=/sbin:/usr/sbin:/bin:/usr/bin
INITEOF

# Inyectar ZGATE_SECRET desde el entorno
echo "export ZGATE_SECRET=\"${ZGATE_SECRET:-zgate-dev-default}\"" >> $TARGET_DIR/init

# Continuar con el resto del script
cat >> $TARGET_DIR/init << 'INITEOF2'

# 🎮 Gaming Network Optimization (ultra-low latency)
echo "⚡ Aplicando optimizaciones de red para gaming..."

# Busy polling (reduce latencia en ~2-3ms)
echo 50 > /proc/sys/net/core/busy_poll
echo 50 > /proc/sys/net/core/busy_read

# Network backlog aumentado
echo 300000 > /proc/sys/net/core/netdev_max_backlog

# NIC tuning para baja latencia
ethtool -C eth0 rx-usecs 10 rx-frames 4 2>/dev/null || true
ethtool -G eth0 rx 4096 tx 4096 2>/dev/null || true

# Deshabilitar offloads (reduce latencia variable)
ethtool -K eth0 gro off 2>/dev/null || true
ethtool -K eth0 gso off 2>/dev/null || true

# 🎯 CPU Pinning & Interrupt Affinity (reduce jitter ~1ms)
echo "⚡ Configurando CPU pinning para latencia consistente..."

# Pin interrupciones de red a CPU0-1
for irq in \$(grep -E 'eth0|virtio0' /proc/interrupts | cut -d: -f1 | tr -d ' '); do
    echo "0-1" > /proc/irq/\$irq/smp_affinity_list 2>/dev/null || true
done

# RPS: Pin software IRQs a CPU0-1 (bitmask: 0x3 = CPU0,1)
for rps in /sys/class/net/eth*/queues/rx-*/rps_cpus; do
    [ -f "\$rps" ] && echo "3" > "\$rps" 2>/dev/null || true
done

echo "✓ Optimizaciones OS aplicadas (CPU pinning, busy polling, RPS/RFS)"

# Start Z-Gate Agent (ARM64)
echo "Starting Z-Gate Agent (ARM64)..."
/usr/bin/z-gate-agent &

# Init system
exec /sbin/init
INITEOF2

chmod +x $TARGET_DIR/init

echo "✓ /init script generated with ARM64 agent"

# Configurar red para Oracle Cloud
cat > $TARGET_DIR/etc/network/interfaces << NETEOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    pre-up sleep 2
NETEOF

echo "✓ Network configuration for Oracle Cloud"

# Configurar hostname
echo "zgate-oracle-arm64" > $TARGET_DIR/etc/hostname

echo "✓ Post-build ARM64 completed"
POSTEOF

    chmod +x board/zgate/post_build_arm64.sh
    echo -e "${GREEN}  ✓ post_build_arm64.sh creado${NC}"
}
