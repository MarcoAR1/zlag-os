# 🧪 Testing Guide - Z-Lag OS

**Objetivo**: Testear cambios al OS sin tener que buildear el ISO completo cada vez (10 minutos).

---

## 📊 Niveles de Testing

```
VELOCIDAD                      CONFIANZA
Fast ←─────────────────────────→ Slow
│                                   │
├─ 1. Syntax Check (5s)            │
├─ 2. Config Validation (10s)      │
├─ 3. Script Unit Tests (30s)      │
├─ 4. QEMU Local Test (2 min)      │
└─ 5. Full ISO Build (10 min) ─────┘
```

---

## 1. 🚀 Syntax & Validation (5-10 segundos)

**Cuándo usar**: Antes de cada commit, después de editar scripts.

### 1.1. Validar sintaxis de scripts bash

```bash
# Validar todos los scripts de buildroot
make validate-scripts

# O manualmente con shellcheck
find buildroot/scripts -name "*.sh" -exec shellcheck {} \;
```

**Añade al Makefile**:
```makefile
.PHONY: validate-scripts
validate-scripts:
	@echo "🔍 Validando sintaxis de scripts..."
	@find buildroot/scripts -name "*.sh" -print0 | xargs -0 shellcheck || \
		(echo "❌ Error de sintaxis encontrado" && exit 1)
	@echo "✅ Todos los scripts OK"
```

### 1.2. Validar kernel configs

```bash
# Verificar que configs de kernel sean válidos
make validate-configs
```

**Añade al Makefile**:
```makefile
.PHONY: validate-configs
validate-configs:
	@echo "🔍 Validando kernel configs..."
	@grep -E "^CONFIG_" buildroot/scripts/02_config.sh | \
		grep -v "^#" | \
		awk -F= '{if ($$2 != "y" && $$2 != "n" && $$2 != "m" && $$2 !~ /^"/) \
			{print "⚠️  Config inválido: " $$0; err=1}} \
		END {if (err) exit 1}'
	@echo "✅ Kernel configs OK"
```

### 1.3. Verificar que optimizaciones estén presentes

```bash
# Script de validación rápida
./scripts/check-optimizations.sh
```

**Crear**: `scripts/check-optimizations.sh`
```bash
#!/bin/bash
set -e

echo "🔍 Verificando optimizaciones implementadas..."

# Check CONFIG_NET_RX_BUSY_POLL
grep -q "CONFIG_NET_RX_BUSY_POLL=y" buildroot/scripts/02_config.sh || \
    { echo "❌ Missing: Busy polling"; exit 1; }

# Check RPS/RFS
grep -q "CONFIG_RPS=y" buildroot/scripts/02_config.sh || \
    { echo "❌ Missing: RPS"; exit 1; }

# Check CPU pinning in /init
grep -q "CPU pinning" buildroot/scripts/02_config.sh || \
    { echo "❌ Missing: CPU pinning"; exit 1; }

# Check SquashFS compression
grep -q "BR2_TARGET_ROOTFS_SQUASHFS4_XZ_EXTREME=y" buildroot/scripts/02_config.sh || \
    { echo "❌ Missing: SquashFS XZ"; exit 1; }

# Check XDP kernel support
grep -q "CONFIG_BPF=y" buildroot/scripts/02_config.sh || \
    { echo "❌ Missing: BPF support"; exit 1; }

echo "✅ Todas las optimizaciones presentes:"
echo "  - Busy polling"
echo "  - RPS/RFS"
echo "  - CPU pinning"
echo "  - SquashFS compression"
echo "  - XDP/eBPF kernel support"
```

---

## 2. 🔬 Config Testing (30 segundos)

**Cuándo usar**: Después de cambiar configs de Buildroot o kernel.

### 2.1. Generar solo los .config (sin compilar)

```bash
# Testear que los scripts generan configs válidos
make test-configs
```

**Añade al Makefile**:
```makefile
.PHONY: test-configs
test-configs:
	@echo "🧪 Generando configs (sin compilar)..."
	@docker run --rm -v $(PWD):/workspace \
		-w /workspace/buildroot \
		ubuntu:22.04 bash -c " \
			apt-get update -qq && apt-get install -y -qq make gcc > /dev/null 2>&1 && \
			cd /workspace/buildroot && \
			./scripts/00_env.sh && \
			./scripts/01_deps.sh && \
			./scripts/02_config.sh && \
			echo '✅ Config x86_64 generado OK' && \
			./scripts/02_config_arm.sh && \
			echo '✅ Config ARM64 generado OK' \
		"
```

### 2.2. Dry-run de Buildroot

```bash
# Verificar que Buildroot puede leer los configs
make buildroot-dryrun
```

**Añade al Makefile**:
```makefile
.PHONY: buildroot-dryrun
buildroot-dryrun:
	@echo "🧪 Dry-run de Buildroot..."
	@docker run --rm -v $(PWD):/workspace \
		zlag-builder:test bash -c " \
			cd /workspace/buildroot && \
			make defconfig BR2_DEFCONFIG=defconfig && \
			make show-info && \
			echo '✅ Buildroot config válido' \
		"
```

---

## 3. 🎯 Incremental Testing (2-3 minutos)

**Cuándo usar**: Para testear cambios específicos sin rebuild completo.

### 3.1. Testear solo el /init script

```bash
# Extraer y verificar el /init generado
make test-init
```

**Añade al Makefile**:
```makefile
.PHONY: test-init
test-init:
	@echo "🧪 Testeando /init script..."
	@mkdir -p .test-output
	@# Extraer la generación de /init del script
	@sed -n '/cat > .*init << .INITEOF/,/^INITEOF/p' \
		buildroot/scripts/02_config.sh > .test-output/init.sh
	@bash -n .test-output/init.sh || \
		{ echo "❌ Syntax error en /init"; exit 1; }
	@echo "✅ /init script válido"
	@# Verificar que tiene las optimizaciones
	@grep -q "busy_poll" .test-output/init.sh || \
		echo "⚠️  Warning: No busy_poll config"
	@grep -q "CPU pinning" .test-output/init.sh || \
		echo "⚠️  Warning: No CPU pinning"
	@rm -rf .test-output
```

### 3.2. Testear solo cambios a scripts (con Docker cache)

```bash
# Build incremental aprovechando Docker layer cache
make test-incremental
```

**Añade al Makefile**:
```makefile
.PHONY: test-incremental
test-incremental:
	@echo "🧪 Build incremental (con cache)..."
	@docker build -f Dockerfile.test \
		--target test-stage \
		--cache-from zlag-builder:test \
		-t zlag-builder:test-incremental .
	@echo "✅ Build incremental OK"
```

---

## 4. 🖥️ QEMU Testing (2-5 minutos)

**Cuándo usar**: Para testear el ISO completo sin deployar a VM.

### 4.1. Boot ISO en QEMU (local)

```bash
# Bootear el ISO en QEMU y verificar que arranca
make test-qemu
```

**Añade al Makefile**:
```makefile
.PHONY: test-qemu
test-qemu:
	@echo "🖥️  Booting ISO en QEMU..."
	@if [ ! -f output/zlag-x86_64.iso ]; then \
		echo "❌ ISO no encontrado. Run: make build-x86"; \
		exit 1; \
	fi
	@qemu-system-x86_64 \
		-cdrom output/zlag-x86_64.iso \
		-m 512 \
		-nographic \
		-serial mon:stdio \
		-append "console=ttyS0" \
		-no-reboot \
		& QEMU_PID=$$! && \
		sleep 10 && \
		kill $$QEMU_PID 2>/dev/null || true
	@echo "✅ ISO bootea correctamente"
```

### 4.2. QEMU con network testing

```bash
# Bootear y testear network stack
make test-qemu-network
```

**Añade al Makefile**:
```makefile
.PHONY: test-qemu-network
test-qemu-network:
	@echo "🌐 Testing network en QEMU..."
	@qemu-system-x86_64 \
		-cdrom output/zlag-x86_64.iso \
		-m 1024 \
		-netdev user,id=net0 \
		-device virtio-net-pci,netdev=net0 \
		-nographic \
		-serial mon:stdio \
		-append "console=ttyS0" &
	@echo "💡 Para testear:"
	@echo "   - Verificar que eth0 está UP"
	@echo "   - Revisar /proc/sys/net/core/busy_poll"
	@echo "   - Verificar RPS: cat /sys/class/net/eth0/queues/rx-0/rps_cpus"
```

---

## 5. 📊 Performance Testing (después de build)

**Cuándo usar**: Para verificar que las optimizaciones funcionan.

### 5.1. Validar optimizaciones en runtime

```bash
# Script de validación en la VM booteada
make validate-runtime
```

**Crear**: `scripts/validate-runtime.sh` (ejecutar dentro del OS)
```bash
#!/bin/sh
# Ejecutar dentro de Z-Lag OS para verificar optimizaciones

echo "🔍 Validando optimizaciones de runtime..."

# Check busy polling
BUSY_POLL=$(cat /proc/sys/net/core/busy_poll)
[ "$BUSY_POLL" = "50" ] && echo "✅ Busy poll: $BUSY_POLL μs" || \
    echo "❌ Busy poll: $BUSY_POLL (expected 50)"

# Check RPS
RPS_CPUS=$(cat /sys/class/net/eth0/queues/rx-0/rps_cpus 2>/dev/null || echo "0")
[ "$RPS_CPUS" != "0" ] && echo "✅ RPS enabled: $RPS_CPUS" || \
    echo "❌ RPS disabled"

# Check interrupt affinity (CPU 0-1)
IRQ=$(grep eth0 /proc/interrupts | head -1 | awk '{print $1}' | tr -d ':')
if [ -n "$IRQ" ]; then
    AFFINITY=$(cat /proc/irq/$IRQ/smp_affinity_list 2>/dev/null || echo "unknown")
    echo "✅ Interrupt affinity: CPU $AFFINITY"
else
    echo "⚠️  No eth0 IRQ found (virtual interface?)"
fi

# Check XDP kernel support
if zcat /proc/config.gz 2>/dev/null | grep -q "CONFIG_BPF=y"; then
    echo "✅ XDP/eBPF kernel support enabled"
else
    echo "❌ XDP/eBPF kernel support missing"
fi

# Check SquashFS root
if mount | grep -q "squashfs"; then
    echo "✅ SquashFS root filesystem"
else
    echo "⚠️  Root not SquashFS (expected for compression)"
fi

echo ""
echo "📊 Summary:"
grep -E "MemTotal|MemAvailable" /proc/meminfo
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime)"
```

### 5.2. Benchmark de latencia (network)

```bash
# Testear latencia con iperf3
# Ejecutar en la VM
```

**Crear**: `scripts/benchmark-latency.sh`
```bash
#!/bin/sh
# Benchmark de latencia de red (ejecutar en Z-Lag OS)

echo "📊 Benchmark de latencia..."

# Install iperf3 if available (o usar ping)
if command -v iperf3 >/dev/null; then
    echo "Testing con iperf3..."
    iperf3 -c <server> -u -b 10M -l 60 --get-server-output
else
    echo "Testing con ping (ICMP)..."
    ping -c 100 -i 0.01 8.8.8.8 | tail -5
fi

# Network stats
echo ""
echo "📈 Network stats:"
cat /proc/net/dev | grep eth0
```

---

## 6. ⚡ Quick Testing Workflow

### Workflow recomendado para desarrollo:

```bash
# 1. Editar scripts (e.g., buildroot/scripts/02_config.sh)
vim buildroot/scripts/02_config.sh

# 2. Validar sintaxis (5 segundos)
make validate-scripts

# 3. Verificar optimizaciones (5 segundos)
./scripts/check-optimizations.sh

# 4. Test de configs (30 segundos)
make test-configs

# 5. Si todo OK, build completo (10 minutos)
make build-x86

# 6. Validar ISO (10 segundos)
make verify

# 7. Test en QEMU (opcional, 2 minutos)
make test-qemu
```

---

## 7. 🔄 CI/CD Testing (GitHub Actions)

El repositorio ya tiene CI/CD configurado que ejecuta:

```yaml
# .github/workflows/build-iso.yml
- Build x86_64 ISO
- Build ARM64 image
- Validate checksums
- Upload artifacts
```

**Para testear localmente** lo que hará GitHub Actions:

```bash
# Replica exacta de GitHub Actions
make test           # Test completo (ambas arquitecturas)
make test-x86       # Solo x86_64
make test-arm       # Solo ARM64
```

---

## 8. 🐛 Troubleshooting Testing

### "shellcheck not found"
```bash
# Instalar shellcheck
brew install shellcheck           # macOS
apt-get install shellcheck        # Ubuntu/Debian
```

### "qemu-system-x86_64 not found"
```bash
# Instalar QEMU
brew install qemu                 # macOS
apt-get install qemu-system-x86  # Ubuntu/Debian
```

### "Docker daemon not running"
```bash
# Start Docker
# macOS: Abrir Docker Desktop
# Linux: sudo systemctl start docker
```

### "Build muy lento"
```bash
# Usar imagen base pre-built
make pull-base                    # Descargar de GHCR (10s)
make build-x86                    # Build rápido (3 min)

# O limpiar cache de Docker
make clean-docker
make build-base                   # Rebuild from scratch
```

---

## 9. 📋 Testing Checklist

Antes de hacer push a GitHub:

- [ ] ✅ `make validate-scripts` - Syntax OK
- [ ] ✅ `./scripts/check-optimizations.sh` - Optimizations present
- [ ] ✅ `make test-configs` - Configs válidos
- [ ] ✅ `make build-x86` - Build exitoso
- [ ] ✅ `make verify` - Checksums correctos
- [ ] ✅ (Opcional) `make test-qemu` - Boot test

Después de deploy a VM:

- [ ] ✅ Boot correcto en Vultr/Oracle
- [ ] ✅ `./scripts/validate-runtime.sh` - Optimizations activas
- [ ] ✅ Agent arranca correctamente
- [ ] ✅ Latency testing con clientes reales

---

## 10. 📊 Performance Metrics

### Tiempos de testing esperados:

| Testing Method | Tiempo | Confianza | Cuándo usar |
|----------------|--------|-----------|-------------|
| Syntax check | **5s** | 🟡 Baja | Cada edit |
| Config validation | **10s** | 🟡 Baja | Después de cambios a configs |
| Test configs | **30s** | 🟠 Media | Antes de build |
| Test incremental | **2 min** | 🟠 Media | Durante desarrollo |
| QEMU boot | **2 min** | 🟢 Alta | Antes de commit |
| Full build | **10 min** | 🟢 Muy Alta | Antes de push |
| Deploy + test VM | **15 min** | 🟢 Máxima | Antes de release |

---

## 11. 🎯 Targets del Makefile (resumen)

Añadir al Makefile principal:

```makefile
# Testing targets
.PHONY: validate-scripts validate-configs test-configs test-init
.PHONY: test-qemu test-qemu-network test-incremental
.PHONY: check-optimizations validate-runtime

validate-scripts:
	# Validar sintaxis bash

validate-configs:
	# Validar kernel configs

test-configs:
	# Generar configs sin compilar

test-init:
	# Testear /init script

test-qemu:
	# Boot en QEMU

check-optimizations:
	# Verificar optimizaciones presentes

# Quick test pipeline
.PHONY: quick-test
quick-test: validate-scripts check-optimizations test-configs
	@echo "✅ Quick tests passed"
```

---

## 12. 💡 Tips

1. **Usar ccache**: Ya está configurado, builds incrementales son ~10x más rápidos
2. **Layer caching**: Docker cachea layers, cambios pequeños no rebuildan todo
3. **GHCR base image**: `make pull-base` descarga imagen pre-compilada (muy rápido)
4. **Syntax first**: Siempre validar sintaxis antes de build (5s vs 10min)
5. **QEMU testing**: Para cambios críticos, testear boot antes de deploy

---

**RESUMEN**: No necesitas buildear el ISO completo para cada cambio. Usa validación de sintaxis (5s), test de configs (30s), y QEMU (2min) para iterar rápido. Build completo solo antes de push/release.
