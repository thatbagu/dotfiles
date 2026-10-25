# k8s-rendered

Generated Kubernetes manifests for the homelab cluster. **Do not edit by hand.**

The source lives on `main` in `modules/system/k8s/` (nixidy modules). On every
push to `main`, `.github/workflows/k8s-render.yml` renders it and commits the
result here. Argo CD syncs the cluster from this branch: `apps/` holds the
Argo CD Applications, every other directory is one application's manifests.
