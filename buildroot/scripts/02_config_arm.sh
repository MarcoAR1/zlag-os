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
        
        # Eliminar configuraciones x86_64 incompatibles
        sed -i '/^BR2_x86_64=y/d' configs/zgate_arm64_defconfig
        sed -i '/^BR2_TARGET_GRUB2_PC=y/d' configs/zgate_arm64_defconfig
        sed -i '/^BR2_TARGET_GRUB2_BOOT_PARTITION=/d' configs/zgate_arm64_defconfig
        sed -i '/^BR2_TARGET_GRUB2_BUILTIN_CONFIG_PC=/d' configs/zgate_arm64_defconfig
        sed -i '/^BR2_TARGET_GRUB2_BUILTIN_MODULES_PC=/d' configs/zgate_arm64_defconfig
        sed -i '/^BR2_TARGET_ROOTFS_ISO9660/d' configs/zgate_arm64_defconfig
        
        # Insertar Configuración ARM64 al inicio
        sed -i '1i\
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
BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="board/zgate/linux_arm64.config"
BR2_ROOTFS_POST_BUILD_SCRIPT="board/zgate/post_build_arm64.sh"

# --- COMPRESSION ---
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
        echo -e "${GREEN}  ✓ ARM64 config created: configs/zgate_arm64_defconfig${NC}"
    else
        echo -e "${RED}ERROR: configs/zgate_defconfig not found${NC}"
        exit 1
    fi

    # 2. CONFIGURACIÓN DE KERNEL ARM64 (FULL ARMOR + LOGGING + INGRESS)
    # Sincronizado 100% con la versión x86
    echo -e "${YELLOW}  → Generando linux_arm64.config...${NC}"
    cat > board/zgate/linux_arm64.config << 'EOF'
# Linux Kernel Configuration for ARM64 (Oracle Cloud Ampere A1)
CONFIG_ARM64=y
CONFIG_64BIT=y
CONFIG_UNWINDER_FRAME_POINTER=y

# --- VIRTUALIZATION ---
CONFIG_ARCH_VIRT=y
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_NET=y
CONFIG_VIRTIO_BLK=y
CONFIG_VIRTIO_MMIO=y

# --- NETWORKING ---
CONFIG_NET=y
CONFIG_INET=y
CONFIG_IPV6=y
CONFIG_PACKET=y
CONFIG_NET_CORE=y
CONFIG_IP_ADVANCED_ROUTER=y
CONFIG_IP_MULTIPLE_TABLES=y
CONFIG_NET_SCHED=y

# --- FIREWALL CORE ---
CONFIG_NETFILTER=y
CONFIG_NETFILTER_ADVANCED=y
CONFIG_NETFILTER_INGRESS=y       # <--- CRÍTICO: Habilita hook ingress
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
CONFIG_NFT_LOG=y               # Frontend de log
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
CONFIG_NFT_FLOW_OFFLOAD=y        # <--- Conecta NFT con Flowtable

# --- TRAFFIC CONTROL (QoS & INGRESS) ---
CONFIG_NET_CLS_ACT=y             # Requerido para hooks ingress complejos
CONFIG_NET_SCH_INGRESS=y

# --- NAT ---
CONFIG_NF_NAT=y
CONFIG_NF_NAT_MASQUERADE=y

# --- SECURITY ---
CONFIG_SPECULATION_MITIGATIONS=y
CONFIG_MITIGATION_SPECTRE_V2=y
CONFIG_MITIGATION_MELTDOWN=y
CONFIG_STACKPROTECTOR=y
CONFIG_STACKPROTECTOR_STRONG=y
CONFIG_STRICT_KERNEL_RWX=y

# --- WIREGUARD ---
CONFIG_WIREGUARD=y

# --- NETWORK PERFORMANCE ---
CONFIG_NET_RX_BUSY_POLL=y
CONFIG_RPS=y
CONFIG_RFS_ACCEL=y
CONFIG_XDP_SOCKETS=y
CONFIG_BPF_SYSCALL=y
CONFIG_BPF_JIT=y

# --- FILESYSTEM ---
CONFIG_EXT4_FS=y
CONFIG_TMPFS=y
EOF
    echo -e "${GREEN}  ✓ linux_arm64.config creado${NC}"

    # 3. POST-BUILD SCRIPT ARM64 (Optimizado y Dinámico)
    echo -e "${YELLOW}  → Generando post_build_arm64.sh...${NC}"
    cat > board/zgate/post_build_arm64.sh << 'POSTEOF'
#!/bin/bash
# Post-build script for ARM64 (Oracle Cloud)
TARGET_DIR=$1
BOARD_DIR=$(dirname $0)

# === LIMPIEZA TOTAL DE INIT SCRIPTS ===
echo "🧹 Limpiando scripts init default..."
rm -f ${TARGET_DIR}/etc/init.d/S*

# Instalar GRUB Config (Esto faltaba en versiones anteriores)
mkdir -p ${TARGET_DIR}/boot/grub
cp board/zgate/menu.cfg ${TARGET_DIR}/boot/grub/grub.cfg

# Generar /init
cat > $TARGET_DIR/init << 'INITEOF'
#!/bin/sh
export PATH=/sbin:/usr/sbin:/bin:/usr/bin

# Mount virtual filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mount -t tmpfs tmpfs /run
mkdir -p /run/lock /run/log /tmp /usr/share/udhcpc
chmod 1777 /tmp

echo "--- 🚀 Z-GATE OS STARTED (ARM64) ---"
INITEOF

cat >> $TARGET_DIR/init << 'INITEOF2'

echo "⚡ Iniciando configuración de red..."

# 1. Loopback (Silenciando error)
ip link set lo up
ip addr add 127.0.0.1/8 dev lo 2>/dev/null || true

# 2. CÁLCULO DINÁMICO DE RECURSOS (ARM64)
# Ampere A1 suele tener 1 hilo por core
CPU_COUNT=$(grep -c processor /proc/cpuinfo)
LAST_CPU=$((CPU_COUNT - 1))
MASK_DEC=$(( (1 << CPU_COUNT) - 1 ))
MASK_HEX=$(printf "%x" $MASK_DEC)

echo "ℹ️ Hardware detectado: $CPU_COUNT CPUs (Máscara RPS: $MASK_HEX)"

# 3. AUTODETECCIÓN DE INTERFAZ WAN
echo "⏳ Detectando interfaz WAN..."
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
    ip link set $IFACE up

    # DHCP (Crítico para OCI)
    echo "🌐 Solicitando IP vía DHCP en $IFACE..."
    udhcpc -b -i $IFACE -s /usr/share/udhcpc/default.script >/dev/null 2>&1 &

    # === FIX RACE CONDITION: ESPERAR A LA RED ===
    echo "⏳ Esperando concesión DHCP..."
    dhcp_wait=0
    has_ip=0
    while [ $dhcp_wait -lt 100 ]; do # Timeout ~10 segundos
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
        echo "⚠️ Timeout DHCP."
    fi

    # C. OPTIMIZACIONES GAMING
    echo 50 > /proc/sys/net/core/busy_poll
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

    # RPS Dinámico
    if [ -d "/sys/class/net/$IFACE/queues" ]; then
        for rps in /sys/class/net/$IFACE/queues/rx-*/rps_cpus; do
            [ -f "$rps" ] && echo "$MASK_HEX" > "$rps" 2>/dev/null || true
        done
        echo "✓ RPS activado en $IFACE usando máscara $MASK_HEX"
    fi
else
    echo "⚠️ ADVERTENCIA: No se detectó interfaz física."
fi

# 4. TEST NFTABLES (DEBUG)
echo "🧪 Testeando soporte Kernel NFTables..."
if nft list ruleset > /dev/null 2>&1; then
    echo "✅ Kernel NFTables: OK"
else
    echo "❌ Kernel NFTables: FALLO"
fi

# 5. INICIO DEL AGENTE Z-GATE
echo "🚀 Iniciando Z-Gate Agent (ARM64)..."
if [ -f "/usr/bin/z-gate-agent" ]; then
    /usr/bin/z-gate-agent &
else
    echo "❌ Error: Binario z-gate-agent no encontrado."
fi

exec /sbin/init
INITEOF2

chmod +x $TARGET_DIR/init

# Configurar script DHCP
cat > $TARGET_DIR/usr/share/udhcpc/default.script << 'DHCPEOF'
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
chmod +x $TARGET_DIR/usr/share/udhcpc/default.script

# Configurar hostname
echo "zgate-oracle-arm64" > $TARGET_DIR/etc/hostname

echo "✓ Post-build ARM64 completed"
POSTEOF

    chmod +x board/zgate/post_build_arm64.sh

    # ==================================================================
    # 4. GRUB CONFIG (ARM64 EFI)
    # ==================================================================
    # Nota: ttyAMA0 es para Oracle Cloud (Ampere)
    # Nota: 'Image' es el nombre estándar del kernel ARM64 en Buildroot
    mkdir -p board/zgate
    cat <<EOF > board/zgate/menu.cfg
set default=0
set timeout=3
menuentry "Z-Gate OS (Oracle ARM64)" {
    linux /Image console=ttyAMA0,115200 console=tty0 quiet panic=10 clocksource=arch_sys_counter
}
EOF

    echo -e "${GREEN}  ✓ post_build_arm64.sh y menu.cfg creados${NC}"
}