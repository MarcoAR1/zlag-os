# 🧪 Testing Guide

Guía completa de testing para Z-Gate OS.

**Testing rápido (sin builds)**: Ver [docs/TESTING-GUIDE.md](docs/TESTING-GUIDE.md)  
**Testing completo (builds)**: Continúa leyendo ⬇️

## 📋 Descripción

El sistema de testing replica **exactamente** el ambiente de GitHub Actions localmente usando Docker, permitiendo:

- ✅ Testear la generación de ISOs sin consumir minutos de GitHub Actions
- ✅ Detectar errores antes de hacer commit/push
- ✅ Validar cambios en los scripts de build
- ✅ Generar ISOs localmente para testing inmediato

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│  GitHub Actions (.github/workflows/build-iso.yml)       │
│  ┌─────────────┐         ┌──────────────┐              │
│  │  x86_64 Job │         │  ARM64 Job   │              │
│  │  Ubuntu 22  │         │  Ubuntu 22   │              │
│  └─────────────┘         └──────────────┘              │
└─────────────────────────────────────────────────────────┘
                           ↓ ↓ ↓
                    REPLICA EXACTA
                           ↓ ↓ ↓
┌─────────────────────────────────────────────────────────┐
│  Docker Local (Dockerfile.test)                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Ubuntu 22.04                                    │   │
│  │  - Mismas dependencias                           │   │
│  │  - Mismo proceso de build                        │   │
│  │  - Validación de binarios                        │   │
│  │  - Generación de checksums                       │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 📦 Archivos

### 1. `Dockerfile.test`
Imagen Docker que replica el ambiente de Ubuntu 22.04 de GitHub Actions con todas las dependencias necesarias.

### 2. `docker-test-entrypoint.sh`
Script que se ejecuta dentro del container y replica exactamente los pasos de las GitHub Actions:
- Verifica binarios del agent
- Crea archivo de secretos
- Ejecuta `setup.sh` o `setup_arm.sh`
- Calcula checksums
- Genera reportes

### 3. `test-build.sh`
Script de conveniencia para facilitar el uso del sistema de testing desde el host.

## 🚀 Uso Rápido

### Paso 1: Construir la imagen Docker (solo primera vez)

```bash
./test-build.sh build
```

Esto descarga Ubuntu 22.04 e instala todas las dependencias (~2GB).

### Paso 2: Asegurarse de tener los binarios del agent

```bash
# En el repo PRIVADO (paseo-vpn-gaming)
cd /path/to/paseo-vpn-gaming
make build-agent update-zgate-os
```

Esto copia los binarios a `../zgate-os/bin/`

### Paso 3: Ejecutar tests

```bash
# Testear solo x86_64 (más rápido, ~15 min)
./test-build.sh x86_64

# Testear solo ARM64 (~30-60 min primera vez)
./test-build.sh arm64

# Testear ambos
./test-build.sh both
```

### Paso 4: Verificar resultados

```bash
./test-build.sh verify
```

## 📝 Comandos Disponibles

```bash
./test-build.sh build          # Construir imagen Docker
./test-build.sh x86_64         # Test solo x86_64 (Vultr)
./test-build.sh arm64          # Test solo ARM64 (Oracle)
./test-build.sh both           # Test ambas arquitecturas
./test-build.sh clean          # Limpiar outputs
./test-build.sh shell          # Abrir shell en container
./test-build.sh verify         # Verificar ISOs generados
./test-build.sh help           # Mostrar ayuda
```

## 🔐 Variables de Entorno (Opcional)

Para testing con secretos reales:

```bash
export ZGATE_SECRET="tu-secret-real"
export VULTR_API_KEY="tu-api-key"

./test-build.sh both
```

Si no se proporcionan, se usan valores mock para testing.

## 📊 Outputs Esperados

### x86_64 (Vultr)
```
buildroot/isos/vultr-x86_64/
├── zgate-vultr-x86_64.iso       # ~200-300MB
└── checksums.txt                # SHA256
```

### ARM64 (Oracle Cloud)
```
buildroot/isos/oracle-arm64/
├── zgate-oracle-arm64.ext4      # ~200-300MB
└── checksums.txt                # SHA256
```

## 🐛 Debugging

### Abrir shell interactivo en el container

```bash
./test-build.sh shell

# Dentro del container
cd /workspace/buildroot
ls -la
./setup.sh build  # Build manual
```

### Ver logs detallados

Los logs completos se muestran durante la ejecución del build.

### Verificar que los binarios se copiaron correctamente

```bash
./test-build.sh shell

# Dentro del container
ls -lh /workspace/buildroot/board/zgate/rootfs-overlay/usr/bin/
```

## ⚡ Tips de Performance

### 1. Cachear descargas de Buildroot

Las descargas de Buildroot se cachean automáticamente en `buildroot/dl/`. No borres este directorio entre builds.

### 2. Usar Docker con recursos suficientes

Asigna al menos:
- **CPU**: 4 cores
- **RAM**: 8GB
- **Disco**: 20GB libres

Configura en Docker Desktop → Settings → Resources

### 3. Build incremental

Los builds subsecuentes son más rápidos porque Buildroot cachea compilaciones previas.

## 🔄 Workflow Completo

```bash
# 1. En repo privado: compilar agent
cd /path/to/paseo-vpn-gaming
make build-agent update-zgate-os

# 2. En repo público: construir imagen Docker (solo primera vez)
cd /path/to/zgate-os
./test-build.sh build

# 3. Test local antes de push
./test-build.sh both

# 4. Verificar outputs
./test-build.sh verify

# 5. Si todo OK, commit y push
git add bin/ buildroot/
git commit -m "chore: Update agent binaries"
git push origin main

# 6. GitHub Actions auto-compila (40 min) y crea release
```

## 🆚 Comparación: Local vs GitHub Actions

| Aspecto | Local (Docker) | GitHub Actions |
|---------|----------------|----------------|
| Tiempo x86_64 | ~15 min | ~20 min |
| Tiempo ARM64 | ~30-60 min | ~40-60 min |
| Costo | Gratis (tu CPU) | Gratis (2000 min/mes) |
| Debugging | Interactivo | Logs online |
| Iteraciones | Ilimitadas | Limitadas por cuota |
| Internet | Solo 1ra vez | Siempre |

## ❓ FAQ

### ¿Por qué tarda tanto el build ARM64?

Cross-compilation de ARM64 en x86_64 es más lenta que native. Primera vez: ~60 min. Subsecuentes: ~30 min.

### ¿Puedo ejecutar solo una parte del build?

Sí, usa el shell interactivo:
```bash
./test-build.sh shell
cd /workspace/buildroot
make menuconfig  # Configurar manualmente
```

### ¿Los ISOs generados localmente son idénticos a los de GitHub?

Casi. Pueden haber diferencias mínimas en timestamps, pero funcionalmente son idénticos.

### ¿Qué hago si el build falla?

1. Verifica que los binarios del agent existan: `ls -lh bin/`
2. Limpia outputs: `./test-build.sh clean`
3. Reconstruye: `./test-build.sh build`
4. Intenta de nuevo: `./test-build.sh both`
5. Si persiste, usa: `./test-build.sh shell` para debugging

## 📚 Referencias

- [Buildroot Manual](https://buildroot.org/downloads/manual/manual.html)
- [GitHub Actions Workflow](.github/workflows/build-iso.yml)
- [Setup Scripts](buildroot/setup.sh) y [ARM Setup](buildroot/setup_arm.sh)

## 🎯 Próximos Pasos

Una vez que los ISOs locales se generen correctamente:

1. ✅ Verificar con `./test-build.sh verify`
2. ✅ Commit y push al repo
3. ✅ GitHub Actions generará release automáticamente
4. ✅ Brain descargará los ISOs del release

---

**Nota**: Este sistema de testing ahorra tiempo y dinero permitiendo detectar errores antes de consumir minutos de GitHub Actions.
