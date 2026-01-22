#!/bin/bash
# scripts/03_agent.sh

build_agent() {
    echo -e "${BLUE}[📦] Compilando Agente Go...${NC}"
    mkdir -p board/zgate/rootfs-overlay/usr/bin
    
    pushd "$AGENT_SRC_DIR" > /dev/null
    
    # Compilación estática pura para Linux x64 desde cmd/agent/
    if CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "../../buildroot/board/zgate/rootfs-overlay/usr/bin/z-gate-agent" ./cmd/agent; then
        echo -e "${GREEN}[OK] Agente compilado correctamente.${NC}"
    else
        echo -e "${RED}[✘] Error compilando el agente.${NC}"
        popd > /dev/null
        exit 1
    fi
    popd > /dev/null
}