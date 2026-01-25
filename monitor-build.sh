#!/bin/bash
# ==============================================================================
# Monitor de Build - Z-Lag ISO Builder
# ==============================================================================
# Monitorea el progreso del build en tiempo real
# ==============================================================================

WORKSPACE="/Users/A446116/Documents/persona-projects/zlag-os"
LOG_FILE="$WORKSPACE/build-test.log"

echo "======================================================================"
echo "  📊 MONITOR DE BUILD - Z-Lag"
echo "======================================================================"
echo ""

while true; do
    clear
    echo "======================================================================"
    echo "  📊 ESTADO DEL BUILD - $(date '+%H:%M:%S')"
    echo "======================================================================"
    echo ""
    
    # Verificar si el proceso Docker está corriendo
    if docker ps | grep -q zlag-builder; then
        echo "✅ Proceso Docker: ACTIVO"
    else
        echo "❌ Proceso Docker: NO ACTIVO"
        echo ""
        echo "Verificando ISOs generados..."
        echo ""
        ls -lh "$WORKSPACE/buildroot/output/"*.iso 2>/dev/null || echo "❌ No se encontraron ISOs"
        break
    fi
    
    echo ""
    echo "======================================================================"
    echo "  📝 ÚLTIMAS LÍNEAS DEL LOG"
    echo "======================================================================"
    
    if [ -f "$LOG_FILE" ]; then
        tail -30 "$LOG_FILE"
        echo ""
        echo "======================================================================"
        echo "  📈 ESTADÍSTICAS"
        echo "======================================================================"
        echo "Tamaño del log: $(du -h "$LOG_FILE" | cut -f1)"
        echo "Líneas totales: $(wc -l < "$LOG_FILE")"
    else
        echo "⏳ Esperando inicio del build..."
    fi
    
    sleep 5
done
