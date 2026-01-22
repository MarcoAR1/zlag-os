#!/bin/bash
# Wrapper para compilar Buildroot en macOS con PATH limpio

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# PATH limpio sin espacios (requerido por Buildroot)
# Incluir /usr/local/bin para Homebrew tools (wget, etc)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Variables esenciales
export HOME="$HOME"
export TERM="${TERM:-xterm-256color}"
export SHELL="/bin/bash"

# Deshabilitar auto-update de Homebrew
export HOMEBREW_NO_AUTO_UPDATE=1

echo "🚀 Building with clean PATH: $PATH"

# Verificar herramientas críticas
if ! command -v wget >/dev/null 2>&1; then
    echo "⚠️  wget not found, installing via Homebrew..."
    if command -v brew >/dev/null 2>&1; then
        brew install wget
    else
        echo "❌ Homebrew not found. Please install wget manually or install Homebrew."
        exit 1
    fi
fi

# Ejecutar setup.sh con entorno limpio
exec ./setup.sh "$@"
