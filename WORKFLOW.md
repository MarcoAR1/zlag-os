# 🔄 Workflow: Private Repo ↔ Public Repo

## Arquitectura

```
paseo-vpn-gaming (PRIVATE)          zgate-os (PUBLIC)
├── zgate/brain/           →        
├── zgate/agent/           →        bin/ (binarios compilados)
├── zgate/cmd/agent/       →        
└── ...                             buildroot/ (configs)
                                    .github/workflows/ (CI/CD)
```

## 📋 Flujo de Trabajo

### 1. Desarrollo en Repo Privado

```bash
cd /Users/A446116/Documents/persona-projects/paseo-vpn-gaming

# Desarrollar normalmente
vim zgate/cmd/agent/main.go
git commit -m "feat: optimize WireGuard handshake"
```

### 2. Compilar Agent

```bash
# Makefile target (crear)
make build-agent

# Compila:
# - bin/z-gate-agent-x86_64
# - bin/z-gate-agent-arm64
```

### 3. Actualizar Repo Público

```bash
# Makefile target (crear)
make update-zgate-os

# Copia binarios a:
# ../zgate-os/bin/z-gate-agent-x86_64
# ../zgate-os/bin/z-gate-agent-arm64
```

### 4. Push a Repo Público

```bash
cd ../zgate-os
git add bin/
git commit -m "chore: Update agent binaries"
git push origin main

# GitHub Actions auto-compila ISOs (40 min)
```

### 5. Brain Descarga ISOs

```bash
cd ../paseo-vpn-gaming/zgate
./zgate -region sao

# Brain automáticamente:
# 1. Busca último release en zgate-os
# 2. Descarga ISO x86_64
# 3. Ordena a Vultr importar
# 4. Deploy VPS
```

## 🔧 Makefile para Automatizar

Crear en repo privado:

```makefile
# paseo-vpn-gaming/Makefile

.PHONY: build-agent update-zgate-os

build-agent:
	@echo "🔨 Compilando agent x86_64..."
	cd zgate && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags="-s -w" \
		-o ../bin/z-gate-agent-x86_64 \
		./cmd/agent
	
	@echo "🔨 Compilando agent ARM64..."
	cd zgate && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
		-ldflags="-s -w" \
		-o ../bin/z-gate-agent-arm64 \
		./cmd/agent
	
	@echo "✅ Binarios compilados:"
	@ls -lh bin/z-gate-agent-*

update-zgate-os: build-agent
	@echo "📦 Copiando binarios a zgate-os..."
	@cp bin/z-gate-agent-x86_64 ../zgate-os/bin/
	@cp bin/z-gate-agent-arm64 ../zgate-os/bin/
	@echo "✅ Binarios actualizados en zgate-os/bin/"
	@echo ""
	@echo "🚀 Próximos pasos:"
	@echo "   cd ../zgate-os"
	@echo "   git add bin/"
	@echo "   git commit -m 'chore: Update agent binaries'"
	@echo "   git push"
```

## 📊 Diagrama de Flujo

```
┌─────────────────────┐
│ Desarrollar         │
│ en paseo-vpn-gaming │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ make build-agent    │
│ (compilar binarios) │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ make update-zgate-os│
│ (copiar a zgate-os) │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ cd ../zgate-os      │
│ git push            │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ GitHub Actions      │
│ (build ISOs 40min)  │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ Release publicado   │
│ con ISOs            │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│ Brain descarga      │
│ y deploya           │
└─────────────────────┘
```

## ⏱️ Tiempos

| Paso | Duración |
|------|----------|
| Compilar agent | ~10 seg |
| Copiar a zgate-os | ~1 seg |
| Push + CI trigger | ~5 seg |
| GitHub Actions build | ~40 min |
| Brain download + deploy | ~5 min |
| **Total** | **~45 min** |

## 🔐 Seguridad

### Lo que SE expone (público):
- ✅ Buildroot configs (genérico)
- ✅ Binarios compilados (difícil reverse)
- ✅ Scripts de build

### Lo que NO se expone (privado):
- ❌ Código fuente Brain
- ❌ Código fuente Agent
- ❌ Lógica de routing
- ❌ Base de datos de rutas
- ❌ Algoritmos de optimización

## 📝 Notas

- Los binarios son **statically linked** (sin dependencias)
- ISOs son **reproducibles** (mismo código = mismo ISO)
- Releases se crean automáticamente con tag `iso-YYYYMMDD-HHMM-SHA`
- Brain usa GitHub Releases API para descarga
