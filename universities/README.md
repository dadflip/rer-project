# RER Universities - Central Configuration & Unified Launcher

**Central Config & Unified Launcher**: Single-point configuration and flexible deployment orchestration

## Files

- **`defaults.env`** : Default values shared across all universities
- **`configs/<UNIV>.env`** : Per-university configuration (BASE_CIDR, LOCAL_DOMAIN, etc.)
- **`render_configs.sh`** : Legacy renderer (directly generates *.univ.env files)
- **`launch.sh`** : Unified launcher with flexible flags (recommended)

## Quick Start

### Option 1: Full deployment (all-in-one)

```bash
# Deploy everything for UTBM: init networks, generate configs, build images, deploy nodes
./universities/launch.sh -a UTBM
```

### Option 2: Step-by-step deployment

```bash
# 1. Initialize networks for UTBM
./universities/launch.sh -n UTBM

# 2. Generate per-university configs only
./universities/launch.sh -g UTBM

# 3. Generate local config templates
./universities/launch.sh -l UTBM

# 4. Build images (if applicable)
./universities/launch.sh -b UTBM

# 5. Deploy specific nodes
./universities/launch.sh --deploy-dns UTBM
./universities/launch.sh --deploy-postgres UTBM
./universities/launch.sh --deploy-wireguard UTBM
```

### Option 3: Config generation only

```bash
# Generate both university and local configs
./universities/launch.sh -c UTBM
```

## Launcher Flags

- `-h, --help`              Show help message
- `-n, --init-networks`     Initialize Docker networks for the university
- `-g, --gen-univ-config`   Generate per-university config files (*.univ.env)
- `-l, --gen-local-config`  Generate local config templates (*.local.env)
- `-b, --build-images`      Build Docker images (backend, frontend)
- `-d, --deploy-all`        Deploy all nodes (DNS/DHCP, Postgres, Wireguard)
- `--deploy-dns`            Deploy DNS/DHCP node only
- `--deploy-postgres`       Deploy Postgres node only
- `--deploy-wireguard`      Deploy Wireguard node only
- `-a, --all`               Run all steps: init-networks, gen configs, build, deploy
- `-c, --config-only`       Generate configs only (gen-univ + gen-local)
- `--clean`                 Clean all Docker resources (containers, images, volumes, networks) for the university
- `-r, --registry REGISTRY` Set Docker registry (for build-images)
- `-t, --tag TAG`           Set image tag (default: latest)

## Configuration Structure

### Per-University (Auto-generated)

The launcher generates these files from `universities/configs/<UNIV>.env`:

- `dns-dhcp-node/dns-dhcp.univ.env`     (LAN, DHCP, DNS IPs, upstream DNS, etc.)
- `postgres-node/postgres.univ.env`     (DB IP, university name)
- `vpn-network-node/wireguard.univ.env` (VPN subnet, Wireguard IPs, server URL)

### Local Overrides (Operator-maintained)

Each node also uses a local config for deployment-specific values:

- `dns-dhcp-node/dns-dhcp.local.env`     (PUID, PGID, TZ, ports)
- `postgres-node/postgres.local.env`     (DB credentials, ports)
- `vpn-network-node/wireguard.local.env` (Wireguard PEERS, SERVERPORT, etc.)

## Customization

### Edit University Configuration

```bash
# Edit the university config
vim universities/configs/UTBM.env
```

Example content:
```
BASE_CIDR=10.10.0.0/16
SHORT_NAME=UTBM
UNIVERSITY_NAME="UTBM"
LOCAL_DOMAIN=utbm.rer.lan
```

### Edit Default Values

```bash
# Edit shared defaults (TZ, PUID/PGID, DNS servers, etc.)
vim universities/defaults.env
```

### Edit Local Overrides

After running `launch.sh`, edit the local .env files directly:

```bash
vim dns-dhcp-node/dns-dhcp.local.env
vim postgres-node/postgres.local.env
vim vpn-network-node/wireguard.local.env
```

## Networks

The launcher creates two Docker networks per university:

- `lan-local-<univ>` : Bridge network for nodes (derived from BASE_CIDR /16)
- `vpn-net-<univ>`   : VPN network for Wireguard (derived from VPN subnet /26)

## Available Universities

```bash
ls universities/configs/ | sed 's/\.env$//'
```

Currently: CAM, LMU, OXF, UHA, UTBM, UZH

## Legacy Usage

If you prefer the direct renderer:

```bash
# Generate *.univ.env files directly
./universities/render_configs.sh UTBM

# Then deploy manually
./dns-dhcp-node/deploy-dns-dhcp-node.sh
./postgres-node/deploy-postgres-node.sh
./vpn-network-node/deploy-wireguard-node.sh
```

## Utility Scripts

Located in `universities/scripts/`:

### Active Scripts

- **`build-images.sh`** : Build Docker images for backend and frontend
  ```bash
  REGISTRY=my-registry.com TAG=v1.0 ./build-images.sh
  ```

- **`clean-docker.sh`** : Clean all Docker resources (interactive confirmation)
  ```bash
  ./clean-docker.sh
  ```

### Via launch.sh

These scripts are also integrated into `launch.sh`:

```bash
./universities/launch.sh -b UTBM        # Build images
./universities/launch.sh --clean UTBM   # Clean resources for university
```

### Archived Scripts

Deprecated scripts have been moved to `universities/scripts/archive/`:

- `deploy-docker-local.sh` : Local microservices deployment (dev env)
- `deploy-k8s-local.sh` : Kubernetes deployment (handled separately)
- `new-project.sh` : Project structure generator
- `mount-container` : Container mount utility
- `rer-lan` : Advanced network CLI management tool

See `universities/scripts/README.md` for more details.
