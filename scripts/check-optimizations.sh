#!/bin/bash
set -e

echo "🔍 Verificando optimizaciones implementadas..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Counter for checks
CHECKS_PASSED=0
CHECKS_TOTAL=0

check_config() {
    local config=$1
    local file=$2
    local description=$3
    
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    
    if grep -q "$config" "$file"; then
        echo "  ✅ $description"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        echo "  ❌ $description - MISSING: $config"
        return 1
    fi
}

echo ""
echo "📦 Verificando x86_64 configs..."

# x86_64 checks
X86_CONFIG="$PROJECT_ROOT/buildroot/scripts/02_config.sh"

check_config "CONFIG_NET_RX_BUSY_POLL=y" "$X86_CONFIG" "Busy polling"
check_config "CONFIG_RPS=y" "$X86_CONFIG" "RPS (Receive Packet Steering)"
check_config "CONFIG_RFS_ACCEL=y" "$X86_CONFIG" "RFS (Receive Flow Steering)"
check_config "CPU pinning" "$X86_CONFIG" "CPU pinning & interrupt affinity"
check_config "BR2_TARGET_ROOTFS_SQUASHFS=y" "$X86_CONFIG" "SquashFS compression"
check_config "BR2_TARGET_ROOTFS_SQUASHFS4_XZ_EXTREME=y" "$X86_CONFIG" "SquashFS XZ extreme"
check_config "CONFIG_BPF=y" "$X86_CONFIG" "BPF/eBPF support"
check_config "CONFIG_XDP_SOCKETS=y" "$X86_CONFIG" "XDP sockets"

echo ""
echo "📦 Verificando ARM64 configs..."

# ARM64 checks
ARM_CONFIG="$PROJECT_ROOT/buildroot/scripts/02_config_arm.sh"

check_config "CONFIG_NET_RX_BUSY_POLL=y" "$ARM_CONFIG" "Busy polling (ARM64)"
check_config "CONFIG_RPS=y" "$ARM_CONFIG" "RPS (ARM64)"
check_config "CONFIG_RFS_ACCEL=y" "$ARM_CONFIG" "RFS (ARM64)"
check_config "CPU pinning" "$ARM_CONFIG" "CPU pinning (ARM64)"
check_config "BR2_TARGET_ROOTFS_SQUASHFS=y" "$ARM_CONFIG" "SquashFS (ARM64)"
check_config "BR2_TARGET_ROOTFS_SQUASHFS4_XZ_EXTREME=y" "$ARM_CONFIG" "SquashFS XZ (ARM64)"
check_config "CONFIG_BPF=y" "$ARM_CONFIG" "BPF/eBPF (ARM64)"
check_config "CONFIG_XDP_SOCKETS=y" "$ARM_CONFIG" "XDP sockets (ARM64)"

echo ""
echo "🔍 Verificando que XDP NO está implementado en OS..."

# Verificar que XDP fue removido (no debe tener compilación ni loading)
CHECKS_TOTAL=$((CHECKS_TOTAL + 2))

if ! grep -q "clang.*xdp_wireguard" "$X86_CONFIG"; then
    echo "  ✅ XDP compilation removida de x86_64"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  ❌ XDP compilation todavía presente en x86_64 (debería estar en agent)"
fi

if ! grep -q "ip link set.*xdpgeneric.*xdp_wireguard" "$X86_CONFIG"; then
    echo "  ✅ XDP loading removido de x86_64"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  ❌ XDP loading todavía presente en x86_64 (debería estar en agent)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Resultado: $CHECKS_PASSED/$CHECKS_TOTAL checks pasaron"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
    echo "✅ TODAS LAS OPTIMIZACIONES IMPLEMENTADAS CORRECTAMENTE"
    echo ""
    echo "Optimizaciones activas:"
    echo "  🚀 Busy polling (CONFIG_NET_RX_BUSY_POLL)"
    echo "  🚀 RPS/RFS (multi-core packet steering)"
    echo "  🚀 CPU pinning & interrupt affinity"
    echo "  📦 SquashFS XZ extreme compression"
    echo "  🧪 XDP/eBPF kernel support (para agent)"
    echo ""
    echo "XDP implementation: Agent-owned (docs/AGENT-XDP-INTEGRATION.md)"
    exit 0
else
    echo "❌ FALTAN OPTIMIZACIONES - Revisar configs"
    exit 1
fi
