#!/bin/bash
set -e

echo "🔍 Verificando optimizaciones implementadas en Zlag..."

# 1. DETECCIÓN DE RUTAS
# SCRIPT_DIR será ".../tu-proyecto/scripts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_ROOT será ".../tu-proyecto"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/" && pwd)"

# Definimos las rutas exactas que pediste
X86_CONFIG="$PROJECT_ROOT/buildroot/scripts/02_config.sh"
ARM_CONFIG="$PROJECT_ROOT/buildroot/scripts/02_config_arm.sh"

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
echo "   Ruta: $X86_CONFIG"

if [ ! -f "$X86_CONFIG" ]; then
    echo "⛔ ERROR CRÍTICO: No encuentro el archivo."
    echo "   Verifica que exista: buildroot/scripts/02_config.sh"
    exit 1
fi

check_config "CONFIG_NET_RX_BUSY_POLL=y" "$X86_CONFIG" "Busy polling"
check_config "CONFIG_RPS=y" "$X86_CONFIG" "RPS (Receive Packet Steering)"
check_config "CONFIG_RFS_ACCEL=y" "$X86_CONFIG" "RFS (Receive Flow Steering)"
check_config "# IRQ Affinity" "$X86_CONFIG" "CPU pinning & interrupt affinity"
check_config "BR2_TARGET_ROOTFS_SQUASHFS=y" "$X86_CONFIG" "SquashFS compression"
check_config "BR2_TARGET_ROOTFS_SQUASHFS4_XZ_EXTREME=y" "$X86_CONFIG" "SquashFS XZ extreme"
check_config "CONFIG_BPF_SYSCALL=y" "$X86_CONFIG" "BPF/eBPF support"
check_config "CONFIG_XDP_SOCKETS=y" "$X86_CONFIG" "XDP sockets"

echo ""
echo "📦 Verificando ARM64 configs..."
echo "   Ruta: $ARM_CONFIG"

if [ ! -f "$ARM_CONFIG" ]; then
    echo "⛔ ERROR CRÍTICO: No encuentro el archivo."
    echo "   Verifica que exista: buildroot/scripts/02_config_arm.sh"
    exit 1
fi

check_config "CONFIG_NET_RX_BUSY_POLL=y" "$ARM_CONFIG" "Busy polling (ARM64)"
check_config "CONFIG_RPS=y" "$ARM_CONFIG" "RPS (ARM64)"
check_config "CONFIG_RFS_ACCEL=y" "$ARM_CONFIG" "RFS (ARM64)"
check_config "# IRQ Affinity" "$ARM_CONFIG" "CPU pinning (ARM64)"
check_config "BR2_TARGET_ROOTFS_SQUASHFS=y" "$ARM_CONFIG" "SquashFS (ARM64)"
check_config "BR2_TARGET_ROOTFS_SQUASHFS4_XZ_EXTREME=y" "$ARM_CONFIG" "SquashFS XZ (ARM64)"
check_config "CONFIG_BPF_SYSCALL=y" "$ARM_CONFIG" "BPF/eBPF (ARM64)"
check_config "CONFIG_XDP_SOCKETS=y" "$ARM_CONFIG" "XDP sockets (ARM64)"

echo ""
echo "🔍 Verificando que XDP NO está implementado en OS (Debe estar en Agente)..."

CHECKS_TOTAL=$((CHECKS_TOTAL + 2))

# Verificamos que NO existan reglas de compilación de XDP en el OS
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
    echo "  🚀 CPU pinning (IRQ Affinity)"
    echo "  📦 SquashFS XZ extreme compression"
    echo "  🧪 eBPF/XDP kernel support (User-space Agent owned)"
    exit 0
else
    echo "❌ FALTAN OPTIMIZACIONES - Revisar configs"
    exit 1
fi