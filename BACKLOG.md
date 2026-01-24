# 📝 Backlog de Mejoras - Z-Gate OS

> **Última actualización**: 23 de enero de 2026  
> **Contexto**: Gaming VPN OS - Optimizado para ultra-baja latencia

---

## ✅ Completado (Sprint 1)

- [x] **ccache**: 90% más rápido builds incrementales (10min → 1min)
- [x] **Kernel hardening**: Spectre/Meltdown + stack protection
- [x] **Parallel CI builds**: x86_64 + ARM64 simultáneos (50% más rápido)
- [x] **Gaming network optimization**: Busy polling, RPS, RFS, interrupt coalescing

---

## 🎯 Mejoras Futuras (Priorizadas)

### Alta Prioridad (Gaming Latency)

#### 1. XDP (eXpress Data Path)
**Impacto**: ⭐⭐⭐⭐⭐ (Crítico - reduce latencia 50%)  
**Esfuerzo**: 🔧🔧🔧🔧 (Alto - 2-3 días)  
**Descripción**: Bypass completo del stack de red del kernel  

**Beneficios**:
- Reduce latencia ~2-5ms adicionales
- Procesamiento de paquetes en driver level
- Compatible con WireGuard (XDP redirect)

**Riesgo**: Requiere kernel 5.10+ (✅ tenemos 6.1) y drivers con soporte XDP

**Implementación**:
```bash
# Kernel configs
CONFIG_XDP_SOCKETS=y
CONFIG_BPF_JIT=y
CONFIG_BPF_SYSCALL=y

# Cargar programa XDP en runtime
ip link set dev eth0 xdp obj xdp_redirect.o
```

**Prioridad**: ALTA - Siguiente sprint si capacidad se vuelve limitante

---

#### 2. AF_XDP User-Space Sockets
**Impacto**: ⭐⭐⭐⭐ (Alto - kernel bypass parcial)  
**Esfuerzo**: 🔧🔧🔧🔧🔧 (Muy alto - requiere modificar agent)  
**Descripción**: Procesar paquetes WireGuard en user-space

**Beneficios**:
- Zero-copy packet processing
- Reduce context switches kernel ↔ user
- ~1-2ms latencia adicional reducida

**Riesgo**: Requiere cambios significativos en agent (Go)

**Prioridad**: MEDIA - Solo si XDP no es suficiente

---

#### 3. CPU Pinning & NUMA Optimization
**Impacto**: ⭐⭐⭐ (Medio - reduce jitter)  
**Esfuerzo**: 🔧🔧 (Bajo - 1 día)  
**Descripción**: Pin WireGuard processing a CPUs dedicados

**Beneficios**:
- Reduce jitter por CPU migration
- Mejor cache locality
- Latencia más consistente

**Implementación**:
```bash
# /init script
# Pin WireGuard interrupts a CPU0-1
echo 1 > /proc/irq/$(grep eth0 /proc/interrupts | cut -d: -f1)/smp_affinity_list

# Pin agent a CPU2-3
taskset -c 2,3 /usr/bin/z-gate-agent
```

**Prioridad**: MEDIA - Mejora jitter, no latencia absoluta

---

### Media Prioridad (Build & Development)

#### 4. SquashFS Compression
**Impacto**: ⭐⭐ (Bajo - solo tamaño)  
**Esfuerzo**: 🔧 (Muy bajo - 30 minutos)  
**Descripción**: Comprimir rootfs para ISOs más pequeños

**Beneficios**:
- ISOs: 50MB → 35MB (-30%)
- Descarga más rápida desde GitHub Releases
- No impact en performance (read-only)

**Implementación**:
```bash
# buildroot/scripts/02_config.sh
BR2_TARGET_ROOTFS_SQUASHFS=y
BR2_TARGET_ROOTFS_SQUASHFS4_XZ=y  # Mejor compresión
```

**Prioridad**: BAJA - Nice to have, no crítico

---

#### 5. Pre-commit Hooks
**Impacto**: ⭐⭐ (Bajo - calidad de código)  
**Esfuerzo**: 🔧🔧 (Bajo - 1 hora)  
**Descripción**: Validar cambios antes de commit

**Beneficios**:
- Prevenir pushes con errores
- Validar syntax de scripts
- Formatear código automáticamente

**Implementación**:
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Validar shellcheck en scripts
find buildroot/scripts -name "*.sh" -exec shellcheck {} \;

# Validar binarios en bin/
./bin/validate.sh
```

**Prioridad**: BAJA - Mejora workflow, no performance

---

### Baja Prioridad (Experimental)

#### 6. DPDK (Data Plane Development Kit)
**Impacto**: ⭐⭐⭐⭐⭐ (Crítico - pero extremo)  
**Esfuerzo**: 🔧🔧🔧🔧🔧🔧 (Muy alto - semanas)  
**Descripción**: Kernel bypass completo, PMD drivers

**Beneficios**:
- Latencia sub-microsegundo
- 10-100M pkt/s capacity
- Polling 100% CPU dedicado

**Riesgo**: 
- ❌ Requiere reescribir WireGuard en user-space
- ❌ +500% CPU usage (polling 100%)
- ❌ Solo vale para >1000 jugadores/VM

**Prioridad**: MUY BAJA - Overkill para gaming VPN

---

## ❌ Rechazado (No Implementar)

### 1. OS-Level Observability
**Razón**: Agent (Go) ya maneja observabilidad (JSON logging, Prometheus)  
**Overhead**: +5-10% CPU para syslog/métricas duplicadas  
**Decisión**: Mantener OS minimal, observabilidad en agent

---

### 2. Signed Images (Image Signing)
**Razón**: Proyecto privado, únicos consumidores  
**Overhead**: PKI infrastructure, key management  
**Protección actual**: GitHub HTTPS + SHA256 + binary validation  
**Decisión**: No necesario para consumo interno

---

### 3. Spot Instances (AWS)
**Razón**: No estamos en AWS  
**Infraestructura actual**: Vultr + Oracle Cloud (sin spot pricing)  
**Decisión**: Scaling manual suficiente (1-2 devs)

---

## 📊 Matriz de Priorización

| Mejora | Latencia | Esfuerzo | ROI | Prioridad |
|--------|----------|----------|-----|-----------|
| XDP | -2-5ms | Alto | ⭐⭐⭐⭐⭐ | ALTA |
| CPU Pinning | -1ms jitter | Bajo | ⭐⭐⭐ | MEDIA |
| AF_XDP | -1-2ms | Muy Alto | ⭐⭐⭐⭐ | MEDIA |
| SquashFS | 0ms | Muy Bajo | ⭐⭐ | BAJA |
| Pre-commit | 0ms | Bajo | ⭐⭐ | BAJA |
| DPDK | -5ms | Extremo | ⭐ | MUY BAJA |

---

## 🎯 Próximo Sprint (Recomendación)

### Opción A: XDP Implementation (Si necesitamos más capacidad)
- Implementar XDP redirect para WireGuard
- Cargar programa eBPF en /init
- Testear latencia con XDP vs sin XDP
- **Objetivo**: 300 → 500 jugadores/VM

### Opción B: Optimizations Incremental (Si capacidad actual suficiente)
- CPU pinning (1 día)
- SquashFS compression (30 min)
- Pre-commit hooks (1 hora)
- **Objetivo**: Mejorar jitter y build workflow

### Opción C: Mantener Status Quo
- Sprint 1 ya cumple objetivos (<5ms latency)
- Capacidad actual (300 jugadores/VM) suficiente
- Enfocarse en agent features, no OS

**Recomendación**: Opción C → Mantener OS estable, iterar en agent

---

## 📚 Referencias

- [XDP Tutorial](https://www.kernel.org/doc/html/latest/networking/af_xdp.html)
- [DPDK Gaming](https://www.dpdk.org/)
- [CPU Pinning](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/performance_tuning_guide/sect-red_hat_enterprise_linux-performance_tuning_guide-cpu-configuration_suggestions)

---

**Nota**: Este OS está optimizado para gaming (latencia > throughput). Cualquier mejora debe reducir latencia/jitter, no aumentar throughput/CPU efficiency.
