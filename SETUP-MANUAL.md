# 🚀 Setup Manual sin GitHub CLI

## Paso 1: Crear Repo en GitHub.com (2 min)

1. Abre tu navegador en: https://github.com/new

2. Configura el repo:
   - **Repository name**: `zgate-os`
   - **Description**: "Z-Gate Buildroot ISO Builder - Public build system"
   - **Visibility**: ✅ **PUBLIC** (importante para GitHub Actions gratis)
   - **Initialize**: ❌ NO marcar "Add a README" (ya lo tenemos)
   - ❌ NO agregar .gitignore (ya lo tenemos)
   - ❌ NO agregar license

3. Click **"Create repository"**

## Paso 2: Configurar Remote y Push (1 min)

Copia estos comandos (GitHub te los mostrará después de crear el repo):

```bash
cd /Users/A446116/Documents/persona-projects/zgate-os

# Configurar remote (reemplaza MarcoAR1 con tu username si es diferente)
git remote add origin https://github.com/MarcoAR1/zgate-os.git

# Verificar remote
git remote -v

# Renombrar branch a main (si no lo está)
git branch -M main

# Push inicial
git push -u origin main
```

Si te pide autenticación:
- **Username**: Tu usuario de GitHub
- **Password**: Usa un **Personal Access Token** (NO tu password de GitHub)
  - Ve a: https://github.com/settings/tokens
  - "Generate new token (classic)"
  - Scope: Marca `repo` (full control)
  - Copy el token y úsalo como password

## Paso 3: Configurar Secrets (3 min)

1. Ve a: https://github.com/MarcoAR1/zgate-os/settings/secrets/actions

2. Click **"New repository secret"**

3. Primer secret:
   - **Name**: `ZGATE_SECRET`
   - **Value**: [Pega tu ZGATE_SECRET aquí]
   - Click "Add secret"

4. Segundo secret:
   - **Name**: `VULTR_API_KEY`
   - **Value**: [Pega tu VULTR_API_KEY aquí]
   - Click "Add secret"

### ¿Dónde encuentro estos valores?

**ZGATE_SECRET**:
```bash
# En tu máquina local
cd /Users/A446116/Documents/persona-projects/paseo-vpn-gaming
cat buildroot/.secrets | grep ZGATE_SECRET
```

**VULTR_API_KEY**:
- Ve a: https://my.vultr.com/settings/#settingsapi
- O busca en tu `.env` local
- O en `buildroot/.secrets`

## Paso 4: Verificar GitHub Actions (inmediato)

1. Ve a: https://github.com/MarcoAR1/zgate-os/actions

2. Deberías ver un workflow corriendo automáticamente después del push

3. Click en el workflow para ver progreso

4. Tiempo estimado: **~40 minutos**
   - Build x86_64: ~30-40 min
   - Build ARM64: ~40-60 min (en paralelo)

## Paso 5: Verificar Release (~40 min después)

1. Ve a: https://github.com/MarcoAR1/zgate-os/releases

2. Deberías ver un release nuevo con tag: `iso-20260122-HHMM-abc123`

3. Archivos incluidos:
   - `zgate-vultr-x86_64.iso` (~50 MB)
   - `zgate-oracle-arm64.ext4` (~50 MB)
   - `checksums.txt` (SHA256 hashes)

## 🔧 Troubleshooting

### Error: "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/MarcoAR1/zgate-os.git
```

### Error: "Authentication failed"
No uses tu password de GitHub. Necesitas un **Personal Access Token**:
1. https://github.com/settings/tokens
2. "Generate new token (classic)"
3. Scope: `repo` (marcar)
4. Usa el token como password

### Workflow no se ejecuta automáticamente
Ve a Settings → Actions → General → Workflow permissions:
- ✅ "Read and write permissions"
- ✅ "Allow GitHub Actions to create and approve pull requests"

### Build falla con "secrets not found"
Verifica que los secrets estén configurados:
```
Settings → Secrets and variables → Actions
```

Debes ver:
- ✅ ZGATE_SECRET
- ✅ VULTR_API_KEY

## 📋 Checklist

Antes de continuar, verifica:

- [ ] Repo creado en GitHub como **PUBLIC**
- [ ] Remote configurado: `git remote -v` muestra `origin`
- [ ] Push exitoso: `git push -u origin main`
- [ ] Secrets configurados (2 secrets visibles en Settings)
- [ ] GitHub Actions ejecutándose (ve a Actions tab)
- [ ] Workflow en progreso (color amarillo 🟡)

## ⏱️ Timeline

| Fase | Duración | Status |
|------|----------|--------|
| Crear repo GitHub | ~2 min | Manual |
| Configurar remote | ~30 seg | Terminal |
| Push inicial | ~10 seg | Terminal |
| Configurar secrets | ~3 min | Manual |
| GitHub Actions build | ~40 min | Automático |
| Release creado | Automático | Automático |
| **Total** | **~45 min** | |

## 🎉 Siguiente Paso

Una vez que el workflow complete (~40 min), actualiza Brain:

```bash
cd /Users/A446116/Documents/persona-projects/paseo-vpn-gaming
```

Edita `zgate/brain/infrastructure/api/github_releases.go`:
```go
const (
    GITHUB_RELEASES_OWNER = "MarcoAR1"  // Tu username
    GITHUB_RELEASES_REPO  = "zgate-os"  // Ya no "paseo-vpn-gaming"
)
```

Luego prueba:
```bash
cd zgate/brain
./zgate -region sao
```

Brain descargará el ISO automáticamente desde GitHub Releases.

---

**Creado**: 22 de enero de 2026  
**Método**: Manual (sin GitHub CLI)
