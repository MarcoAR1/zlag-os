# Z-Gate Docker Builder - Compilar ISOs en macOS/Windows

## 🚀 Quick Start

### 1. Instalar Docker Desktop
- macOS: https://www.docker.com/products/docker-desktop
- Windows: https://www.docker.com/products/docker-desktop

### 2. Configurar secrets
```bash
cd buildroot
cp .secrets.example .secrets
# Editar .secrets con tus valores reales
```

### 3. Compilar ISO
```bash
# Build rápido x86_64 (Vultr)
./docker-build.sh update x86_64

# Build completo desde cero
./docker-build.sh build x86_64

# Build ARM64 (Oracle Cloud)
./docker-build.sh update arm64

# Compilar ambas arquitecturas
./docker-build.sh both
```

## 📋 Comandos Disponibles

| Comando | Descripción | Tiempo |
|---------|-------------|--------|
| `update` | Build incremental (recomendado) | ~10-15 min |
| `build` | Build completo desde cero | ~30-60 min |
| `clean` | Limpiar outputs | ~1 seg |
| `shell` | Shell interactivo en container | - |
| `both` | Compilar x86_64 + arm64 | ~40 min |

## 🎯 Uso Detallado

### Build Incremental (Más Rápido)
```bash
./docker-build.sh update x86_64
```
Usa cache de compilaciones previas. Ideal para desarrollo.

### Build Completo (Desde Cero)
```bash
./docker-build.sh build x86_64
```
Compila todo desde cero. Necesario después de cambios en kernel.

### Shell Interactivo
```bash
./docker-build.sh shell

# Dentro del container:
cd /build/buildroot
./setup.sh update
make menuconfig  # Configurar Buildroot
```

## 📦 Outputs

### x86_64 (Vultr)
```
buildroot/isos/vultr-x86_64/
├── zgate-vultr-x86_64.iso      # ISO bootable (~50MB)
└── checksums.txt                # SHA256
```

### ARM64 (Oracle)
```
buildroot/isos/oracle-arm64/
├── zgate-oracle-arm64.ext4     # Filesystem image (~50MB)
└── checksums.txt                # SHA256
```

## 🔧 Troubleshooting

### Error: "Cannot connect to Docker daemon"
```bash
# macOS: Abrir Docker Desktop
open -a Docker

# Windows: Iniciar Docker Desktop desde el menú
```

### Error: "Permission denied"
```bash
# Agregar tu usuario al grupo docker (Linux)
sudo usermod -aG docker $USER
# Logout y login de nuevo
```

### Build muy lento
```bash
# Verificar recursos de Docker Desktop:
# Settings → Resources → CPU/Memory
# Recomendado: 4+ CPUs, 8GB+ RAM
```

### Cache corrupto
```bash
# Limpiar y rebuild
./docker-build.sh clean
rm -rf dl/
./docker-build.sh build x86_64
```

## 🐳 Gestión de Imagen Docker

### Rebuild imagen (después de actualizar Dockerfile)
```bash
docker rmi zgate-buildroot-builder
./docker-build.sh update x86_64  # Rebuildeará automáticamente
```

### Ver logs de build
```bash
docker run --rm -it \
  -v "$(pwd)/..:/build" \
  -w /build/buildroot \
  zgate-buildroot-builder \
  bash -c "./setup.sh update 2>&1 | tee build.log"
```

### Inspeccionar imagen
```bash
docker run --rm -it zgate-buildroot-builder bash
go version
gcc --version
ls -la /usr/bin | grep gcc
```

## 🚀 CI/CD con GitHub Actions

El workflow `.github/workflows/build-iso.yml` compila automáticamente:

- **On push**: Compila x86_64 ISO
- **On tag**: Compila y sube a GitHub Releases
- **Manual**: Permite elegir arquitectura

```bash
# Crear release
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions compilará y subirá ISO automáticamente
```

## 📊 Performance

| Arquitectura | Primera Build | Build Incremental | Tamaño Final |
|--------------|---------------|-------------------|--------------|
| x86_64       | ~30-45 min    | ~10-15 min        | ~50MB        |
| ARM64        | ~45-60 min    | ~15-20 min        | ~50MB        |

*Tiempos en MacBook Pro M1 con Docker Desktop (4 CPUs, 8GB RAM)*

## 🔐 Secrets Management

**NUNCA** commitear `.secrets` al repositorio.

```bash
# .secrets (gitignored)
export ZGATE_SECRET="production-secret-key-2024"
export VULTR_API_KEY="ABCDEFGH123456"
export MAX_MINUTES="120"
```

Para GitHub Actions, configurar en:
`Settings → Secrets and variables → Actions → New repository secret`
