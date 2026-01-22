#!/bin/bash
# wget wrapper usando curl para Buildroot en macOS

# Convertir argumentos de wget a curl
OUTPUT_FILE=""
URL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -O)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --output-document=*)
            OUTPUT_FILE="${1#*=}"
            shift
            ;;
        -q|--quiet)
            QUIET=1
            shift
            ;;
        -*)
            # Ignorar otras opciones
            shift
            ;;
        *)
            URL="$1"
            shift
            ;;
    esac
done

# Usar curl
if [ -n "$OUTPUT_FILE" ] && [ "$OUTPUT_FILE" != "-" ]; then
    exec curl -fsSL -o "$OUTPUT_FILE" "$URL"
else
    exec curl -fsSL "$URL"
fi
