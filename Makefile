# ==============================================================================
# 🛡️  Z-Lag OS - Makefile para Testing, Build Turbo y Release
# ==============================================================================
# Optimizaciones para i5-13600KF (20 hilos / 16GB RAM)
# ==============================================================================

.PHONY: help setup test test-x86 test-arm verify clean shell docker-build
.PHONY: build-base build-x86 build-arm build-both push-base pull-base
.PHONY: local-test-x86 local-test-arm release check-gh info checksums wipe

# Variables de Identidad
REPO_OWNER := marcoar1
REPO_NAME := zlag-os
VERSION := $(shell date +'%Y%m%d-%H%M')
RELEASE_TAG := iso-$(VERSION)

# Variables de Docker
BASE_IMAGE := zlag-buildroot-base:latest
BUILD_IMAGE := zlag-builder:latest
DOCKER_IMAGE := zlag-builder:test
GHCR_BASE := ghcr.io/$(REPO_OWNER)/$(REPO_NAME)/zlag-buildroot-base:latest

# Optimización de Hardware (i5-13600KF)
THREADS := 20
MEM_LIMIT := 16g
MEM_SWAP := 20g

# Colores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m

# ==============================================================================
# Ayuda
# ==============================================================================
help:
	@echo ""
	@echo "$(CYAN)╔═══════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║$(NC) 🛡️  Z-Lag OS - TURBO BUILDER (i5-13600KF Optimized)            $(CYAN)║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)🚀 COMANDOS PRINCIPALES:$(NC)"
	@echo "  $(YELLOW)make release$(NC)         Build completo + Deploy a GitHub"
	@echo "  $(RED)make wipe$(NC)            Limpiar TODO (Docker, Cache, Procesos)"
	@echo ""
	@echo "$(GREEN)📦 Builds Individuales:$(NC)"
	@echo "  make build-base       Construir imagen base"
	@echo "  make build-x86        Build rápido x86_64"
	@echo "  make build-arm        Build rápido ARM64"
	@echo ""

# ==============================================================================
# Release - Build & Deploy
# ==============================================================================
check-gh:
	@command -v gh >/dev/null 2>&1 || { echo "$(RED)❌ gh cli no instalado.$(NC)"; exit 1; }
	@gh auth status >/dev/null 2>&1 || { echo "$(YELLOW)⚠️ No logueado en GH CLI.$(NC)"; exit 1; }

release: check-gh clean-all build-base build-both verify
	@echo "$(CYAN)☁️  Subiendo Release a GitHub...$(NC)"
	gh release create $(RELEASE_TAG) \
		buildroot/output/images/zlag-vultr-x86_64.iso \
		buildroot/output/images/zlag-oracle-arm64.ext4 \
		--repo $(REPO_OWNER)/$(REPO_NAME) \
		--title "Z-Lag OS Production - $(RELEASE_TAG)" \
		--notes "📦 Release generado localmente (i5-13600KF).\n\n**Checksums:**\n- x86_64: $$(sha256sum buildroot/output/images/zlag-vultr-x86_64.iso | cut -d' ' -f1)\n- ARM64: $$(sha256sum buildroot/output/images/zlag-oracle-arm64.ext4 | cut -d' ' -f1)"
	@echo "$(GREEN)✅ RELEASE COMPLETADO EXITOSAMENTE$(NC)"

# ==============================================================================
# Builds Optimizados
# ==============================================================================
build-base:
	@echo "$(CYAN)🏗️  Construyendo imagen base...$(NC)"
	docker build -f Dockerfile.base -t $(BASE_IMAGE) .

build-x86: build-base
	@echo "$(BLUE)🔨 Compilando x86_64 con $(THREADS) hilos...$(NC)"
	@mkdir -p buildroot/output/target/usr/bin
	cp bin/z-lag-agent-x86_64 buildroot/output/target/usr/bin/z-lag-agent
	chmod +x buildroot/output/target/usr/bin/z-lag-agent
	docker build -f Dockerfile.build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(BUILD_IMAGE) .
	docker run --rm --privileged \
		--cpus="$(THREADS)" --memory="$(MEM_LIMIT)" --memory-swap="$(MEM_SWAP)" \
		-v $(PWD):/workspace -v zlag-ccache:/buildroot/dl/ccache \
		$(BUILD_IMAGE) x86_64
	@mv buildroot/output/images/*.iso buildroot/output/images/zlag-vultr-x86_64.iso 2>/dev/null || true

build-arm: build-base
	@echo "$(BLUE)🔨 Compilando ARM64 con $(THREADS) hilos...$(NC)"
	@mkdir -p buildroot/output/target/usr/bin
	cp bin/z-lag-agent-arm64 buildroot/output/target/usr/bin/z-lag-agent
	chmod +x buildroot/output/target/usr/bin/z-lag-agent
	docker build -f Dockerfile.build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(BUILD_IMAGE) .
	docker run --rm --privileged \
		--cpus="$(THREADS)" --memory="$(MEM_LIMIT)" --memory-swap="$(MEM_SWAP)" \
		-v $(PWD):/workspace -v zlag-ccache:/buildroot/dl/ccache \
		$(BUILD_IMAGE) arm64
	@find buildroot/output/images -type f \( -name "*.ext*" -o -name "rootfs.tar" \) -exec mv {} buildroot/output/images/zlag-oracle-arm64.ext4 \; 2>/dev/null || true

build-both: build-x86 build-arm

# ==============================================================================
# Limpieza Profunda (WIPE)
# ==============================================================================
wipe: clean-all
	@echo "$(RED)⚠️  LIMPIEZA TOTAL DE RESIDUOS (WSL + DOCKER)...$(NC)"
	-sudo killall -9 make cc1plus gcc g++ 2>/dev/null || true
	rm -rf ~/.buildroot-ccache
	rm -rf ~/.ccache
	docker system prune -a --volumes -f
	@echo "$(GREEN)✅ Sistema purgado. Cierra la terminal y corre el .bat en Windows.$(NC)"

# ==============================================================================
# Utilidades Secundarias
# ==============================================================================
verify:
	@echo "$(BLUE)🔍 Validando archivos...$(NC)"
	@ls -lh buildroot/output/images/zlag-*
	@if [ ! -s buildroot/output/images/zlag-vultr-x86_64.iso ]; then exit 1; fi
	@if [ ! -s buildroot/output/images/zlag-oracle-arm64.ext4 ]; then exit 1; fi

clean:
	rm -rf buildroot/output/images/*
	rm -rf release_artifacts/*

clean-docker:
	docker rmi $(BUILD_IMAGE) $(BASE_IMAGE) 2>/dev/null || true

clean-all: clean clean-docker