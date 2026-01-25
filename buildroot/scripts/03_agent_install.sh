#!/bin/bash
# scripts/03_agent_install.sh

# Función unificada para copiar el binario pre-compilado
install_prebuilt_agent() {
    local ARCH=$1  # Recibe "arm64" o "x86_64"
    local BIN_SOURCE="/workspace/bin/z-gate-agent-${ARCH}"
    local DEST_DIR="board/zgate/rootfs-overlay/usr/bin"
    local DEST_FILE="${DEST_DIR}/z-gate-agent"

    echo -e "${BLUE}[📦] Instalando Agente pre-compilado para ${ARCH}...${NC}"

    # 1. Verificar que el binario existe (montado desde el GHA)
    if [ ! -f "$BIN_SOURCE" ]; then
        echo -e "${RED}[✘] Error Crítico: No se encuentra el binario en ${BIN_SOURCE}${NC}"
        echo -e "${YELLOW}    Asegúrate de que el volumen -v $(pwd)/bin:/workspace/bin está montado.${NC}"
        ls -l /workspace/bin/ 2>/dev/null || echo "La carpeta /workspace/bin no existe o está vacía."
        exit 1
    fi

    # 2. Crear directorio de destino
    mkdir -p "$DEST_DIR"

    # 3. Copiar y dar permisos
    echo -e "${BLUE}    → Copiando desde: ${BIN_SOURCE}${NC}"
    cp "$BIN_SOURCE" "$DEST_FILE"
    chmod +x "$DEST_FILE"

    # 4. Verificación final
    if [ -f "$DEST_FILE" ]; then
        echo -e "${GREEN}[OK] Agente instalado correctamente en rootfs.${NC}"
        echo -e "    → Tipo de archivo:"
        file "$DEST_FILE"
    else
        echo -e "${RED}[✘] Falló la copia del archivo.${NC}"
        exit 1
    fi
}