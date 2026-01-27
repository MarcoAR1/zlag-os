# ==============================================================================
# 🛡️  Z-Lag OS - Clean Makefile (i5-13600KF Optimized)
# ==============================================================================
.PHONY: build-x86 build-arm release wipe help check-gh

# Identidad y Configuración
REPO_OWNER := marcoar1
REPO_NAME  := zlag-os
VERSION    := $(shell date +'%Y%m%d-%H%M')
TAG        := iso-$(VERSION)

# Colores para la terminal
CYAN   := \033[0;36m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m

# Ayuda por defecto
help:
	@echo ""
	@echo "$(CYAN)╔═══════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║$(NC) 🛡️  Z-Lag OS - TURBO BUILDER (Monolithic Edition)              $(CYAN)║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)🚀 COMANDOS PRINCIPALES:$(NC)"
	@echo "  $(YELLOW)make release$(NC)         Build completo (x86+ARM) + Deploy a GitHub"
	@echo "  $(RED)make wipe$(NC)            Limpiar Docker y temporales (WIPE total)"
	@echo ""

# --- VALIDACIÓN DE GITHUB CLI ---
check-gh:
	@command -v gh >/dev/null 2>&1 || { echo "$(RED)❌ gh cli no instalado.$(NC)"; exit 1; }
	@gh auth status >/dev/null 2>&1 || { echo "$(YELLOW)⚠️ No logueado en GH CLI. Ejecutá: gh auth login$(NC)"; exit 1; }

# --- BUILD x86_64 ---
build-x86:
	@echo "$(CYAN)🚀 [1/2] Iniciando Build x86_64 (Potencia: 20 hilos)...$(NC)"
	docker build --build-arg ARCH=x86_64 -t zlag-build:x86_64 -f Dockerfile.build .
	@mkdir -p output/vultr
	@echo "$(YELLOW)📥 Extrayendo ISO desde el contenedor...$(NC)"
	# Usamos comodín *.iso9660 para evitar errores de nombre exacto
	docker run --rm zlag-build:x86_64 sh -c "cat /zlag/output/images/*.iso9660" > output/vultr/zlag-vultr.iso
	@echo "$(GREEN)✅ ISO lista en: output/vultr/zlag-vultr.iso$(NC)"

# --- BUILD ARM64 ---
build-arm:
	@echo "$(CYAN)🚀 [2/2] Iniciando Build ARM64 (Potencia: 20 hilos)...$(NC)"
	docker build --build-arg ARCH=arm64 -t zlag-build:arm64 -f Dockerfile.build .
	@mkdir -p output/oracle
	@echo "$(YELLOW)📥 Extrayendo Imagen desde el contenedor...$(NC)"
	# Usamos comodín *.ext* porque Buildroot a veces genera .ext2 o .ext4
	docker run --rm zlag-build:arm64 sh -c "cat /zlag/output/images/rootfs.ext*" > output/oracle/zlag-oracle.ext4
	@echo "$(GREEN)✅ Imagen lista en: output/oracle/zlag-oracle.ext4$(NC)"

# --- RELEASE ---
release: check-gh build-x86 build-arm
	@echo "$(CYAN)☁️  Subiendo artefactos a GitHub Release...$(NC)"
	gh release create $(TAG) \
		output/vultr/zlag-vultr.iso \
		output/oracle/zlag-oracle.ext4 \
		--repo $(REPO_OWNER)/$(REPO_NAME) \
		--title "Z-Lag OS Production $(VERSION)" \
		--notes "📦 Release generado localmente con i5-13600KF (20 hilos).\n\n**Checksums:**\n- x86_64: $$(sha256sum output/vultr/zlag-vultr.iso | cut -d' ' -f1)\n- ARM64: $$(sha256sum output/oracle/zlag-oracle.ext4 | cut -d' ' -f1)"
	@echo "$(GREEN)🎉 ¡Release publicado exitosamente!$(NC)"

# --- LIMPIEZA TOTAL ---
wipe:
	@echo "$(RED)⚠️  PURGANDO TODO EL SISTEMA DE DOCKER...$(NC)"
	-docker system prune -a --volumes -f
	rm -rf output/*
	@echo "$(GREEN)✅ Listo. No olvides correr compact_zlag_universal.bat en Windows.$(NC)"