#!/bin/bash
# ==============================================================================
# Script de Validación de Integridad de Binarios
# ==============================================================================
# Valida que los binarios del agent no hayan sido modificados o corrompidos
# usando checksums SHA-256
# ==============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKSUMS_FILE="$SCRIPT_DIR/checksums.sha256"

echo -e "${BLUE}🔐 Validando integridad de binarios del agent...${NC}"
echo ""

# Verificar que existe el archivo de checksums
if [[ ! -f "$CHECKSUMS_FILE" ]]; then
    echo -e "${RED}❌ ERROR: Archivo de checksums no encontrado${NC}"
    echo -e "${YELLOW}   Ubicación esperada: $CHECKSUMS_FILE${NC}"
    echo ""
    echo -e "${YELLOW}💡 Generar checksums con:${NC}"
    echo -e "${YELLOW}   cd bin && sha256sum z-lag-agent-* > checksums.sha256${NC}"
    exit 1
fi

# Validar checksums
cd "$SCRIPT_DIR"
if sha256sum -c "$CHECKSUMS_FILE" 2>/dev/null; then
    echo ""
    echo -e "${GREEN}✅ Todos los binarios son válidos${NC}"
    echo -e "${GREEN}   Integridad verificada correctamente${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ ALERTA: Checksums no coinciden${NC}"
    echo -e "${RED}   Los binarios han sido modificados o están corruptos${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  ADVERTENCIA DE SEGURIDAD:${NC}"
    echo -e "${YELLOW}   - No uses estos binarios en producción${NC}"
    echo -e "${YELLOW}   - Descarga binarios limpios del repositorio privado${NC}"
    echo -e "${YELLOW}   - Regenera checksums: sha256sum z-lag-agent-* > checksums.sha256${NC}"
    exit 1
fi
