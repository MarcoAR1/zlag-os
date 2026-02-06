#!/bin/bash
# ==============================================================================
# 📦 ZLAG AGENT INSTALLER MODULE
# ==============================================================================

# Función unificada para copiar el binario pre-compilado
install_prebuilt_agent() {
    local ARCH=$1  # Recibe "arm64" o "x86_64"
    local BIN_NAME="zlag-agent-${ARCH}"
    local DEST_DIR="board/zlag/rootfs-overlay/usr/bin"
    local DEST_FILE="${DEST_DIR}/zlag-agent" # Nombre final dentro del OS - MUST match init script!

    # Detección inteligente de la ruta del binario
    # 1. Prioridad: Entorno Docker (GitHub Actions)
    if [ -f "/workspace/bin/${BIN_NAME}" ]; then
        BIN_SOURCE="/workspace/bin/${BIN_NAME}"
    # 2. Fallback: Entorno Local (Tu PC)
    elif [ -f "bin/${BIN_NAME}" ]; then
        BIN_SOURCE="bin/${BIN_NAME}"
    else
        # Si llegamos aquí y es un UPDATE, es un error fatal.
        # Si es un BUILD, setup.sh ya manejó la advertencia, pero aquí reportamos.
        echo -e "${RED}[✘] Error: No se encuentra ${BIN_NAME} en /workspace/bin/ ni en bin/${NC}"
        return 1
    fi

    echo -e "${BLUE}[📦] Instalando Agente Zlag (${ARCH})...${NC}"
    echo -e "${BLUE}    Origen: ${BIN_SOURCE}${NC}"
    echo -e "${BLUE}    Destino: ${DEST_FILE}${NC}"

    # 1. Crear directorio de destino si no existe
    if [ ! -d "$DEST_DIR" ]; then
        mkdir -p "$DEST_DIR"
    fi

    # 2. Copiar y dar permisos
    cp "$BIN_SOURCE" "$DEST_FILE"
    chmod +x "$DEST_FILE"

    # 3. Verificación final de integridad
    if [ -f "$DEST_FILE" ]; then
        echo -e "${GREEN}[OK] Agente inyectado correctamente.${NC}"
        # Intentamos mostrar info del archivo para confirmar arquitectura
        file "$DEST_FILE" | cut -d',' -f2 || true
    else
        echo -e "${RED}[✘] Falló la copia del archivo.${NC}"
        exit 1
    fi
}