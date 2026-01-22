#!/bin/bash
# scripts/03_agent_arm.sh - ARM64 Agent Builder

build_agent_arm() {
    echo -e "${BLUE}[📦] Compilando Agente Go para ARM64...${NC}"
    mkdir -p board/zgate/rootfs-overlay/usr/bin
    
    pushd "$AGENT_SRC_DIR" > /dev/null
    
    # Compilación estática pura para Linux ARM64 (Oracle Cloud Ampere A1) desde cmd/agent/
    if CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o "../../buildroot/board/zgate/rootfs-overlay/usr/bin/z-gate-agent" ./cmd/agent; then
        echo -e "${GREEN}[OK] Agente ARM64 compilado correctamente.${NC}"
        
        # Verificar arquitectura
        echo -e "${BLUE}  → Verificando arquitectura...${NC}"
        file "../../buildroot/board/zgate/rootfs-overlay/usr/bin/z-gate-agent"
    else
        echo -e "${RED}[✘] Error compilando el agente ARM64.${NC}"
        popd > /dev/null
        exit 1
    fi
    popd > /dev/null
}
