# Z-Lag OS

## 🎮 Qué es

**Z-Lag OS** es un sistema operativo Linux ultra-minimal optimizado para infraestructura de red con baja latencia.

## 🎯 Para qué sirve

Este OS está diseñado para ejecutar servicios de red donde la latencia es crítica:
- Stack de red optimizado para bajo overhead
- Sistema minimal sin servicios innecesarios
- Kernel configurado para procesamiento rápido de paquetes
- Buildroot-based para mantener tamaño reducido (~50MB)

## 🔧 Componentes

### Sistema Base
- **Buildroot**: Build system para Linux minimal
- **Kernel 6.1 LTS**: Con optimizaciones de red
- **Init script**: Arranque directo sin systemd
- **Tamaño**: ~50MB (ISO x86_64 / rootfs ARM64)

### Optimizaciones de Red
- **Busy polling**: Procesamiento rápido de paquetes
- **RPS/RFS**: Distribución de carga multi-core
- **CPU pinning**: Interrupts dedicados
- **SquashFS compression**: ISOs compactos

## 🏗️ Arquitectura

Sistema operativo minimal enfocado en:
- **Baja latencia**: Kernel y stack de red optimizados
- **Minimal overhead**: Solo componentes esenciales
- **Reproducible**: Build system automatizado con Buildroot

## 🔒 Seguridad

- **Minimal attack surface**: Sin servicios innecesarios (no SSH, no HTTP)
- **Kernel hardening**: Mitigaciones de seguridad habilitadas
- **Inmutable**: Sin package managers en runtime
- **Reproducible builds**: SHA256 checksums automáticos

## 📦 Build Outputs

- **x86_64 ISO**: ~50MB (cloud VMs)
- **ARM64 rootfs**: ~50MB (ARM instances)
- **Distribución**: GitHub Releases automáticos
- **Validación**: SHA256 checksums

## � Build System

- **ccache**: Builds incrementales rápidos
- **Docker**: Ambiente reproducible
- **GitHub Actions**: CI/CD automatizado
- **Buildroot 2023.02.1**: Base del sistema

---

**Última actualización**: 23 de enero de 2026  
**Versión Kernel**: 6.1.100 LTS  
**Buildroot**: 2023.02.1
