# Z-Lag OS

> 🚀 **Linux OS minimal** optimizado para baja latencia  
> 📦 **Buildroot-based**: ~50MB ISOs/rootfs  
> 🔧 **Network-focused**: Stack de red optimizado

## 📦 Qué genera este proyecto

ISOs y rootfs de Linux minimal:

- **x86_64 ISO** → ~50MB (cloud VMs)
- **ARM64 rootfs** → ~50MB (ARM instances)

Optimizado para aplicaciones donde la latencia de red es importante.

Ver [PROJECT.md](PROJECT.md) para detalles técnicos.

## 🚀 Quick Start

### Build Locally (Docker)

```bash
# 1. Build test environment (first time only)
./test-build.sh build

# 2. Generate ISOs
./test-build.sh both          # Both architectures
./test-build.sh x86_64        # x86_64 only (faster)
./test-build.sh arm64         # ARM64 only

# 3. Validate output
./validate-iso.sh output/zlag-os-x86_64.iso
```

### Automated Builds (GitHub Actions)

Every push to `main` triggers automated build:
1. Build base Docker image
2. Build x86_64 ISO (parallel)
3. Build ARM64 rootfs (parallel)
4. Create GitHub Release with artifacts
./test-build.sh verify
./validate-iso.sh both
```

## 📁 Repository Structure

```
zlag-os/
├── bin/                          # Pre-compiled binaries
│   ├── z-lag-agent-x86_64
│   └── z-lag-agent-arm64
├── buildroot/                    # Build configurations
│   ├── scripts/                  # Config generation scripts
│   └── setup*.sh                 # Setup scripts
├── .github/workflows/            # CI/CD automation
├── Dockerfile.*                  # Build containers
├── Makefile                      # Build orchestration
├── test-build.sh                 # Local testing
├── validate-iso.sh               # ISO validation
├── PROJECT.md                    # Gaming optimization details
└── GAMING-OPTIMIZATIONS.md       # Network stack tuning
```

## ⚙️ Características

### Optimizaciones de Red
- **Busy Polling**: Procesamiento rápido de paquetes
- **RPS/RFS**: Distribución multi-core
- **CPU Pinning**: Interrupts dedicados
- **SquashFS**: Compresión de rootfs

### Build System
- **ccache**: Builds incrementales rápidos
- **Parallel builds**: x86_64 + ARM64 simultáneos
- **Docker**: Ambiente reproducible

## 🔐 Seguridad

- Minimal attack surface (sin servicios innecesarios)
- Kernel hardening habilitado
- SHA256 checksums automáticos
- Builds reproducibles

## 📜 License

GPL-2.0 (Buildroot)
