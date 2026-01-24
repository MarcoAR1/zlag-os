# ==============================================================================
# Z-Gate OS - Makefile para Testing y Build Local
# ==============================================================================
# Simplifica los comandos de testing y build optimizado
#
# Uso:
#   make build-base     # Construir imagen base (1 vez)
#   make build-x86      # Build optimizado x86_64
#   make test           # Test completo (ambas arquitecturas)
#   make help           # Mostrar ayuda
# ==============================================================================

.PHONY: help setup test test-x86 test-arm verify clean shell docker-build
.PHONY: build-base build-x86 build-arm build-both push-base pull-base
.PHONY: local-test-x86 local-test-arm

# Variables
DOCKER_IMAGE := zgate-builder:test
BASE_IMAGE := zgate-buildroot-base:latest
BUILD_IMAGE := zgate-builder:latest
GHCR_BASE := ghcr.io/$(shell git config --get remote.origin.url | sed 's/.*github.com[:/]//;s/.git$$//' | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "owner/repo")/zgate-buildroot-base:latest

# Colores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m

# ==============================================================================
# Ayuda (por defecto)
# ==============================================================================
help:
	@echo ""
	@echo "$(CYAN)╔═══════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║$(NC)  🛡️  Z-GATE OS - BUILD & TEST COMMANDS                    $(CYAN)║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)📦 Builds Optimizados (Recomendado):$(NC)"
	@echo "  make build-base     Construir imagen base (solo 1 vez)"
	@echo "  make build-x86      Build rápido x86_64 ISO"
	@echo "  make build-arm      Build rápido ARM64 image"
	@echo "  make build-both     Build rápido de ambos"
	@echo ""
	@echo "$(GREEN)🧪 Testing (Setup anterior):$(NC)"
	@echo "  make setup          Configurar ambiente Docker"
	@echo "  make test           Test completo (x86_64 + ARM64)"
	@echo "  make test-x86       Test solo x86_64"
	@echo "  make test-arm       Test solo ARM64"
	@echo ""
	@echo "$(CYAN)⚡ Local Quick Test (Verificar fix de objtool):$(NC)"
	@echo "  make local-test-x86   Test x86_64 LOCAL (1-2h primera vez)"
	@echo "  make local-test-arm   Test ARM64 LOCAL (1-2h primera vez)"
	@echo ""
	@echo "$(GREEN)🚀 GitHub Container Registry:$(NC)"
	@echo "  make push-base      Subir imagen base a GHCR"
	@echo "  make pull-base      Descargar imagen base de GHCR"
	@echo ""
	@echo "$(GREEN)✅ Validación:$(NC)"
	@echo "  make verify         Verificar ISOs generados"
	@echo "  make checksums      Mostrar checksums"
	@echo ""
	@echo "$(GREEN)🔧 Utilidades:$(NC)"
	@echo "  make clean          Limpiar outputs"
	@echo "  make clean-docker   Limpiar imágenes Docker"
	@echo "  make shell          Shell interactivo"
	@echo ""
	@echo "$(YELLOW)⚡ Quick Start:$(NC)"
	@echo "  1. make build-base    # Primera vez (10 min)"
	@echo "  2. make build-x86     # Builds rápidos (3-5 min)"
	@echo "  3. make verify        # Validar ISOs"
	@echo ""

# ==============================================================================
# Setup - Construir imagen Docker
# ==============================================================================
setup: docker-build
	@echo "$(GREEN)✅ Setup completado$(NC)"
	@echo "$(YELLOW)Ahora puedes ejecutar: make test$(NC)"

docker-build:
	@echo "$(BLUE)🔨 Construyendo imagen Docker...$(NC)"
	@./test-build.sh build

# ==============================================================================
# Testing
# ==============================================================================
test:
	@echo "$(BLUE)🧪 Ejecutando test completo (x86_64 + ARM64)...$(NC)"
	@./test-build.sh both

test-x86:
	@echo "$(BLUE)🧪 Ejecutando test x86_64 (Vultr)...$(NC)"
	@./test-build.sh x86_64

test-arm:
	@echo "$(BLUE)🧪 Ejecutando test ARM64 (Oracle Cloud)...$(NC)"
	@./test-build.sh arm64

# ==============================================================================
# Validación
# ==============================================================================
verify:
	@echo "$(BLUE)🔍 Verificando ISOs/imágenes generados...$(NC)"
	@./test-build.sh verify
	@echo ""
	@./validate-iso.sh both

checksums:
	@echo "$(BLUE)📊 Checksums de ISOs/imágenes:$(NC)"
	@echo ""
	@if [ -f buildroot/isos/vultr-x86_64/checksums.txt ]; then \
		echo "$(GREEN)x86_64 (Vultr):$(NC)"; \
		cat buildroot/isos/vultr-x86_64/checksums.txt; \
		echo ""; \
	fi
	@if [ -f buildroot/isos/oracle-arm64/checksums.txt ]; then \
		echo "$(GREEN)ARM64 (Oracle):$(NC)"; \
		cat buildroot/isos/oracle-arm64/checksums.txt; \
	fi

# ==============================================================================
# Debugging
# ==============================================================================
shell:
	@echo "$(BLUE)🐚 Abriendo shell interactivo en container...$(NC)"
	@./test-build.sh shell

logs:
	@echo "$(BLUE)📋 Logs de último build:$(NC)"
	@echo ""
	@if [ -f buildroot/output/build/build-time.log ]; then \
		tail -100 buildroot/output/build/build-time.log; \
	else \
		echo "$(YELLOW)No se encontraron logs de build$(NC)"; \
	fi

# ==============================================================================
# Limpieza
# ==============================================================================
clean:
	@echo "$(YELLOW)🧹 Limpiando outputs de build...$(NC)"
	@./test-build.sh clean

clean-docker:
	@echo "$(YELLOW)🧹 Limpiando imagen Docker...$(NC)"
	@docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	@echo "$(GREEN)✅ Imagen Docker limpiada$(NC)"

clean-all: clean clean-docker
	@echo "$(GREEN)✅ Limpieza completa finalizada$(NC)"

# ==============================================================================
# Información del sistema
# ==============================================================================
info:
	@echo "$(BLUE)ℹ️  Información del sistema:$(NC)"
	@echo ""
	@echo "Docker:"
	@docker --version || echo "  $(RED)Docker no instalado$(NC)"
	@echo ""
	@echo "Binarios del agent:"
	@ls -lh bin/z-gate-agent-* 2>/dev/null || echo "  $(YELLOW)No encontrados (ejecuta 'make update-agent' en repo privado)$(NC)"
	@echo ""
	@echo "ISOs generados:"
	@if [ -f buildroot/isos/vultr-x86_64/zgate-vultr-x86_64.iso ]; then \
		echo "  $(GREEN)✓ x86_64:$(NC) $$(du -h buildroot/isos/vultr-x86_64/zgate-vultr-x86_64.iso | cut -f1)"; \
	else \
		echo "  $(YELLOW)✗ x86_64 no generado$(NC)"; \
	fi
	@if [ -f buildroot/isos/oracle-arm64/zgate-oracle-arm64.ext4 ]; then \
		echo "  $(GREEN)✓ ARM64:$(NC) $$(du -h buildroot/isos/oracle-arm64/zgate-oracle-arm64.ext4 | cut -f1)"; \
	else \
		echo "  $(YELLOW)✗ ARM64 no generado$(NC)"; \
	fi

# ==============================================================================
# Quick test - Para CI/CD local
# ==============================================================================
quick-test: test-x86 verify
	@echo "$(GREEN)✅ Quick test completado$(NC)"

# ==============================================================================
# Full validation - Antes de push a GitHub
# ==============================================================================
full-validation: test verify checksums
	@echo ""
	@echo "$(GREEN)╔═══════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║$(NC)  ✅ VALIDACIÓN COMPLETA EXITOSA                              $(GREEN)║$(NC)"
	@echo "$(GREEN)╚═══════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Los ISOs están listos. Puedes hacer push a GitHub.$(NC)"
	@echo ""
	@echo "Siguiente paso:"
	@echo "  git add bin/ buildroot/"
	@echo "  git commit -m 'chore: Update agent binaries'"
	@echo "  git push origin main"

# ==============================================================================
# Builds Optimizados con Imagen Base
# ==============================================================================

build-base:
	@echo "$(CYAN)🏗️  Construyendo imagen base de Buildroot...$(NC)"
	@echo "$(YELLOW)Esto tomará ~10 minutos (solo se hace 1 vez)$(NC)"
	docker build -f Dockerfile.base -t $(BASE_IMAGE) .
	@echo "$(GREEN)✅ Imagen base lista: $(BASE_IMAGE)$(NC)"

build-x86: build-base
	@echo "$(CYAN)🔨 Building x86_64 ISO (optimizado con ccache)...$(NC)"
	docker build -f Dockerfile.build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(BUILD_IMAGE) .
	docker run --rm \
		--cpus="4" \
		--memory="8g" \
		--memory-swap="10g" \
		-v $(PWD):/workspace \
		-v zgate-ccache:/buildroot/dl/ccache \
		$(BUILD_IMAGE) x86_64
	@echo "$(GREEN)✅ x86_64 ISO generado (ccache enabled)$(NC)"

build-arm: build-base
	@echo "$(CYAN)🔨 Building ARM64 Image (optimizado con ccache)...$(NC)"
	docker build -f Dockerfile.build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(BUILD_IMAGE) .
	docker run --rm \
		--cpus="4" \
		--memory="8g" \
		--memory-swap="10g" \
		-v $(PWD):/workspace \
		-v zgate-ccache:/buildroot/dl/ccache \
		$(BUILD_IMAGE) arm64
	@echo "$(GREEN)✅ ARM64 Image generado (ccache enabled)$(NC)"

build-both: build-base
	@echo "$(CYAN)🔨 Building ambos ISOs (optimizado con ccache)...$(NC)"
	docker build -f Dockerfile.build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(BUILD_IMAGE) .
	docker run --rm \
		--cpus="4" \
		--memory="8g" \
		--memory-swap="10g" \
		-v $(PWD):/workspace \
		-v zgate-ccache:/buildroot/dl/ccache \
		$(BUILD_IMAGE) both \
		--memory-swap="10g" \
		-v $(PWD):/workspace $(BUILD_IMAGE) both
	@echo "$(GREEN)✅ Ambos ISOs generados$(NC)"

push-base:
	@echo "$(CYAN)📤 Subiendo imagen base a GHCR...$(NC)"
	@echo "Registry: $(GHCR_BASE)"
	docker tag $(BASE_IMAGE) $(GHCR_BASE)
	docker push $(GHCR_BASE)
	@echo "$(GREEN)✅ Imagen subida exitosamente$(NC)"

pull-base:
	@echo "$(CYAN)📥 Descargando imagen base de GHCR...$(NC)"
	docker pull $(GHCR_BASE)
	docker tag $(GHCR_BASE) $(BASE_IMAGE)
	@echo "$(GREEN)✅ Imagen descargada: $(BASE_IMAGE)$(NC)"

# ==============================================================================
# Local Quick Test (Verificar fix antes de GitHub Actions)
# ==============================================================================
local-test-x86:
	@echo "$(CYAN)╔═══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║ 🧪 LOCAL TEST x86_64 (Verificar fix de objtool)         ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)[1/3] Building base image...$(NC)"
	docker build -f Dockerfile.base -t zgate-buildroot-base:local .
	@echo ""
	@echo "$(YELLOW)[2/3] Building x86_64 (esto tomará 1-2 horas primera vez)...$(NC)"
	docker build -f Dockerfile.build \
		--build-arg BASE_IMAGE=zgate-buildroot-base:local \
		-t zgate-builder:x86_64-local .
	@echo ""
	@echo "$(YELLOW)[3/3] Running build...$(NC)"
	mkdir -p output
	docker run --rm \
		-e TERM=linux \
		-e ZGATE_SECRET="test-secret-local" \
		-v $(PWD)/output:/buildroot/isos \
		zgate-builder:x86_64-local x86_64
	@echo ""
	@echo "$(GREEN)✅ SUCCESS! ISO generado en: output/vultr-x86_64/$(NC)"
	@ls -lh output/vultr-x86_64/zgate-vultr-x86_64.iso

local-test-arm:
	@echo "$(CYAN)╔═══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║ 🧪 LOCAL TEST ARM64 (Verificar fix de objtool)          ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)[1/3] Building base image...$(NC)"
	docker build -f Dockerfile.base -t zgate-buildroot-base:local .
	@echo ""
	@echo "$(YELLOW)[2/3] Building ARM64 (esto tomará 1-2 horas primera vez)...$(NC)"
	docker build -f Dockerfile.build \
		--build-arg BASE_IMAGE=zgate-buildroot-base:local \
		-t zgate-builder:arm64-local .
	@echo ""
	@echo "$(YELLOW)[3/3] Running build...$(NC)"
	mkdir -p output
	docker run --rm \
		-e TERM=linux \
		-e ZGATE_SECRET="test-secret-local" \
		-v $(PWD)/output:/buildroot/isos \
		zgate-builder:arm64-local arm64
	@echo ""
	@echo "$(GREEN)✅ SUCCESS! Image generado en: output/oracle-arm64/$(NC)"
	@ls -lh output/oracle-arm64/zgate-oracle-arm64.ext4


	@echo "  git push origin main"
	@echo ""
