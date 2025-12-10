# RER Project Cleanup & Consolidation

## Summary

The RER project has been restructured for better maintainability and clarity.

### What Was Done

1. **Centralized Configuration**
   - Single source of truth per university: `universities/configs/<UNIV>.env`
   - Shared defaults: `universities/defaults.env`
   - Per-node local overrides: `<node>/`<node>`.local.env`

2. **Unified Launcher (`launch.sh`)**
   - Replaced multiple deployment scripts with a single flexible tool
   - Integrated features: init-networks, config generation, building, deployment, cleanup
   - Support for 6 universities: UTBM, UHA, CAM, LMU, OXF, UZH

3. **Dual Env Architecture per Node**
   - `*.univ.env` : Auto-generated per-university configs
   - `*.local.env` : Operator-maintained local overrides
   - No duplication, clean separation of concerns

4. **Script Organization**
   - **Active scripts** in `universities/scripts/`:
     - `build-images.sh` : Build Docker images
     - `clean-docker.sh` : Clean Docker resources
   - **Deprecated scripts** moved to `universities/scripts/archive/`:
     - `deploy-docker-local.sh`, `deploy-k8s-local.sh`, `new-project.sh`, `mount-container`, `rer-lan`

5. **Deploy Scripts Updated** (DNS/DHCP, Postgres, Wireguard)
   - Support optional renderer call
   - Automatic local env template creation
   - Docker Compose .env aggregation for variable substitution

### File Structure After Cleanup

```
universities/
├── launch.sh                    (main orchestrator - recommended)
├── render_configs.sh            (legacy renderer - for backward compat)
├── defaults.env                 (shared defaults)
├── configs/
│   ├── UTBM.env, UHA.env, CAM.env, LMU.env, OXF.env, UZH.env
├── scripts/
│   ├── README.md                (scripts documentation)
│   ├── build-images.sh          (active)
│   ├── clean-docker.sh          (active)
│   └── archive/                 (deprecated scripts)
└── README.md                    (main documentation)
```

### Usage Examples

**Full deployment:**
```bash
./universities/launch.sh -a UTBM
```

**Step-by-step:**
```bash
./universities/launch.sh -n UTBM        # Init networks
./universities/launch.sh -g UTBM        # Generate configs
./universities/launch.sh -b UTBM        # Build images
./universities/launch.sh -d UTBM        # Deploy all nodes
```

**Other operations:**
```bash
./universities/launch.sh --clean UTBM   # Clean resources
./universities/launch.sh -c UHA         # Config generation only
```

### Benefits

✅ **Simplicity**: One script, many capabilities  
✅ **Flexibility**: Modular flags for partial operations  
✅ **Scalability**: Easy to add new universities or nodes  
✅ **Maintainability**: Central config management  
✅ **No Duplication**: Clear separation of generated vs. manual configs  
✅ **Backward Compatible**: Legacy `render_configs.sh` still available  

### Next Steps

1. Test the new unified launcher:
   ```bash
   ./universities/launch.sh -h
   ```

2. Deploy a test university:
   ```bash
   ./universities/launch.sh -c UTBM
   ```

3. Archive or remove old scripts as needed (they're in `scripts/archive/` for reference)
