# Binarios Pre-compilados del Agent

Este directorio contiene los binarios del Z-Lag Agent compilados desde el repositorio privado.

## 📦 Archivos

- `z-lag-agent-x86_64` - Agent para Vultr VPS (Linux x86_64)
- `z-lag-agent-arm64` - Agent para Oracle Cloud (Linux ARM64)

## 🔄 Actualización

Estos binarios son actualizados automáticamente desde el repo privado:

```bash
# En repo privado: paseo-vpn-gaming
make build-agent          # Compila ambas arquitecturas
make update-zlag-os      # Copia a zlag-os/bin/
```

## ⚠️ Importante

**NO commitear binarios manualmente aquí.**  
Usar siempre `make update-zlag-os` desde el repo privado.

## 🔐 Seguridad

- Binarios compilados estáticamente (sin deps)
- CGO_ENABLED=0 (no libc dependency)
- Stripped (-ldflags="-s -w")
- Version info embebida

## 📏 Tamaño Esperado

- x86_64: ~5-6 MB
- ARM64: ~5-6 MB
