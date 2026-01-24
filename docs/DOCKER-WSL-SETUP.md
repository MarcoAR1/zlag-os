# 🐳 Docker en WSL2 - Setup Rápido

## Pre-requisitos

Windows 10/11 con WSL2 habilitado. Si no lo tienes:

```powershell
# En PowerShell como Administrador
wsl --install
wsl --set-default-version 2
```

---

## Instalación Docker en WSL2 (Ubuntu)

### Método 1: Docker Desktop (Recomendado - Más Fácil)

1. **Descargar Docker Desktop para Windows:**
   https://www.docker.com/products/docker-desktop

2. **Durante instalación, habilitar "Use WSL 2 based engine"**

3. **En Configuración de Docker Desktop:**
   - Settings → Resources → WSL Integration
   - Habilitar integración con tu distribución Ubuntu

4. **Verificar en WSL:**
   ```bash
   docker --version
   docker ps
   ```

---

### Método 2: Docker Engine en WSL2 (Más Control)

```bash
# 1. Actualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# 2. Instalar dependencias
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Agregar GPG key de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Agregar repositorio Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Instalar Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Iniciar Docker
sudo service docker start

# 7. Agregar tu usuario al grupo docker (evitar sudo)
sudo usermod -aG docker $USER

# 8. Aplicar cambios (salir y volver a entrar)
newgrp docker

# 9. Verificar instalación
docker --version
docker run hello-world
```

---

## Build Z-Gate en WSL2 (PC de Escritorio)

### Setup Inicial

```bash
# 1. Clonar repo
cd ~
git clone https://github.com/TU_USUARIO/zgate-os.git
cd zgate-os

# 2. Pull de los últimos cambios
git pull origin main

# 3. Verificar que Docker funciona
docker ps
docker info
```

### Optimización para PC Multi-Core

```bash
# Ver cuántos cores tienes
nproc

# Si tienes 16+ cores, ajustar variables de entorno
export MAKEFLAGS="-j$(nproc)"
export DOCKER_BUILDKIT=1
```

### Build Local Rápido

```bash
# Test x86_64 (1-2 horas primera vez, usa TODOS tus cores)
make local-test-x86

# O si prefieres más control:
docker build -f Dockerfile.base -t zgate-buildroot-base:local .
docker build -f Dockerfile.build \
  --build-arg BASE_IMAGE=zgate-buildroot-base:local \
  -t zgate-builder:x86_64-local .

mkdir -p output
docker run --rm \
  --cpus="$(nproc)" \
  -e TERM=linux \
  -e ZGATE_SECRET="test-secret" \
  -v $(pwd)/output:/buildroot/isos \
  zgate-builder:x86_64-local x86_64

# Verificar resultado
ls -lh output/vultr-x86_64/zgate-vultr-x86_64.iso
```

---

## Monitoreo del Build

### Ver progreso en tiempo real

```bash
# En otra terminal WSL
docker ps  # Ver container corriendo

# Ver logs del build
docker logs -f <container_id>

# Ver uso de CPU/RAM
docker stats
```

### Puntos de control

```bash
# Durante el build, verificar que no hay error de objtool
# Buscar estos mensajes:

# ✅ BUENO:
# [✓] x86_64 output ready
# [✓] Buildroot compilation successful

# ❌ MALO:
# make[2]: *** [Makefile:73: objtool] Error 2
# Error en compilación del kernel
```

---

## Tiempos Estimados según Cores

| Cores | Primera Vez | Con Caché |
|-------|-------------|-----------|
| 4 cores | ~2 horas | ~10 min |
| 8 cores | ~1 hora | ~5 min |
| 16 cores | ~30 min | ~3 min |
| 32 cores | ~15 min | ~2 min |

---

## Troubleshooting WSL2

### Docker no inicia en WSL2

```bash
# Verificar que WSL2 está corriendo
wsl --list --verbose

# Reiniciar WSL2 desde PowerShell
wsl --shutdown
wsl

# Iniciar Docker manualmente
sudo service docker start
```

### Auto-start Docker en WSL2

Agregar a `~/.bashrc` o `~/.zshrc`:

```bash
# Auto-start Docker
if ! docker info >/dev/null 2>&1; then
    sudo service docker start
fi
```

### Sin sudo para Docker

```bash
# Si aún pide sudo después de usermod -aG docker
sudo chmod 666 /var/run/docker.sock
```

### Limpiar espacio en disco

```bash
# Ver cuánto espacio usa Docker
docker system df

# Limpiar todo (cuidado!)
docker system prune -a --volumes

# Limpiar solo builds antiguos
docker builder prune -a
```

---

## Pushear desde WSL2

```bash
cd ~/zgate-os

# Verificar cambios
git status

# Commit y push
git add .
git commit -m "fix: objtool disabled + build optimizations"
git push origin main
```

---

## Después del Build Local Exitoso

Una vez que el build local **termine sin errores**:

1. **Verificar ISO generado:**
   ```bash
   ls -lh output/vultr-x86_64/zgate-vultr-x86_64.iso
   sha256sum output/vultr-x86_64/zgate-vultr-x86_64.iso
   ```

2. **Construir imagen pre-compilada (opcional):**
   ```bash
   docker build -f Dockerfile.compiled \
     --build-arg BASE_IMAGE=zgate-buildroot-base:local \
     -t zgate-buildroot-compiled:local .
   
   # Tag y push a GHCR
   docker tag zgate-buildroot-compiled:local ghcr.io/TU_USUARIO/zgate-buildroot-compiled:latest
   docker push ghcr.io/TU_USUARIO/zgate-buildroot-compiled:latest
   ```

3. **Activar GitHub Actions:**
   ```bash
   git push origin main
   ```
   - Ahora GitHub Actions usará tu imagen pre-compilada
   - Builds futuros: **3-5 minutos** en vez de 2 horas

---

## Comandos Útiles Rápidos

```bash
# Ver todos los comandos disponibles
make help

# Limpiar todo
make clean
make clean-docker

# Shell dentro del container
make shell

# Build ARM64 (también optimizado)
make local-test-arm

# Ver logs de Docker
journalctl -u docker.service -f
```

---

## Performance Tips WSL2

### Usar toda la RAM disponible

Crear/editar `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=16GB       # Tu RAM disponible
processors=16     # Tus cores
swap=8GB
localhostForwarding=true
```

Reiniciar WSL2:
```powershell
wsl --shutdown
```

### Mover Docker data a disco más rápido

```bash
# Si tienes SSD/NVMe separado
sudo service docker stop
sudo mv /var/lib/docker /mnt/d/docker-data
sudo ln -s /mnt/d/docker-data /var/lib/docker
sudo service docker start
```

---

## Resumen - Quickstart

```bash
# 1. Instalar Docker (método 2 completo)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# 2. Clonar y build
git clone https://github.com/TU_USUARIO/zgate-os.git
cd zgate-os
git pull origin main

# 3. Build local (usa todos tus cores)
make local-test-x86

# 4. Esperar 15-60 min (según cores)

# 5. Verificar resultado
ls -lh output/vultr-x86_64/zgate-vultr-x86_64.iso
```

---

**Última actualización:** Enero 24, 2026  
**Optimizado para:** PC multi-core con WSL2  
**Tiempo estimado:** 15-30 min en PC de 16+ cores
