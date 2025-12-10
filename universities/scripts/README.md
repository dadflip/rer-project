# RER Scripts

## Active Scripts

- **`build-images.sh`** : Build Docker images for backend and frontend
  ```bash
  REGISTRY=my-registry.com TAG=v1.0 ./build-images.sh
  ```

- **`clean-docker.sh`** : Clean all Docker resources (containers, images, volumes, networks)
  ```bash
  ./clean-docker.sh
  ```

## Archived Scripts (in `archive/`)

These scripts are deprecated or out of scope for the current RER project structure:

- `deploy-docker-local.sh` : Local microservices deployment (dev env)
- `deploy-k8s-local.sh` : Kubernetes deployment (handled separately)
- `new-project.sh` : Project structure generator
- `mount-container` : Container mount utility
- `rer-lan` : Advanced network CLI management tool

## Using launch.sh

The recommended approach is to use the unified launcher:

```bash
./universities/launch.sh -b UTBM        # Build images
./universities/launch.sh --clean UTBM   # Clean resources
./universities/launch.sh -a UTBM        # Full deployment
```

See `universities/README.md` for complete documentation.
