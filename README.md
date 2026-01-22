# Z-Gate OS - Buildroot ISO Builder

> 🔒 **Public repo** for building Z-Gate operating system ISOs.  
> 🔐 **Private logic** in main repository (Brain/Agent code).

## 📦 What This Repo Does

Compiles minimal Linux ISOs for Z-Gate VPN nodes:

- **x86_64** → Vultr VPS (~50MB)
- **ARM64** → Oracle Cloud Ampere A1 (~50MB)

## 🚀 Quick Start

### For Contributors (Public)

This repo contains:
- ✅ Buildroot configurations
- ✅ Pre-compiled agent binaries (`bin/`)
- ✅ Build scripts and Dockerfile
- ❌ NO source code of Brain/Agent (private)

### For Z-Gate Developers (Private Repo Access)

See workflow documentation in private repo.

## 🏗️ Build Process

### Automatic (GitHub Actions)

Every push to `main` triggers:
1. Build x86_64 ISO (30-40 min)
2. Build ARM64 image (40-60 min)
3. Create GitHub Release with ISOs
4. Brain downloads from releases automatically

### Manual (Local with Docker)

```bash
# Build x86_64
cd buildroot
./docker-build.sh update x86_64

# Build ARM64
./docker-build.sh update arm64
```

## 📁 Structure

```
zgate-os/
├── bin/                          # Pre-compiled agent binaries
│   ├── z-gate-agent-x86_64      # From private repo
│   └── z-gate-agent-arm64       # From private repo
├── buildroot/                    # Buildroot configs
│   ├── configs/
│   ├── board/zgate/
│   └── scripts/
├── .github/workflows/            # CI/CD
│   └── build-iso.yml
└── README.md
```

## 🔄 Update Workflow (For Private Repo Maintainers)

```bash
# In private repo (paseo-vpn-gaming)
make build-agent          # Compile agent
make update-zgate-os      # Copy binaries to zgate-os/
cd ../zgate-os
git add bin/
git commit -m "chore: Update agent binaries"
git push                  # Triggers ISO build
```

## 📊 Build Times

| Architecture | First Build | Incremental |
|--------------|-------------|-------------|
| x86_64       | ~30-40 min  | ~10-15 min  |
| ARM64        | ~40-60 min  | ~15-20 min  |

## 🔐 Security

- Agent binaries are **compiled** (not source code)
- Build secrets injected via GitHub Secrets
- ISOs are immutable (reproducible builds)

## 📜 License

Buildroot configurations: GPL-2.0  
Agent binaries: Proprietary (Z-Gate)

## 🔗 Links

- Private Repo: (Access restricted)
- Issues: Report in private repo
- Releases: [GitHub Releases](../../releases)

---

**Note:** This is the PUBLIC build system. The actual VPN logic is in the private repository.
