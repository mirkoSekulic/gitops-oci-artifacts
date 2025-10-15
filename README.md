# GitOps with OCI Artifacts

Demonstrates how to configure GitOps using OCI artifacts with Flux. All cluster deployments are managed from a single source of truth stored as OCI images in a registry.

## Architecture Overview

![Architecture Diagram](diagrams/architecture.excalidraw.svg)

**Registry**: For this demo, a registry runs in-cluster. In production, use a cloud provider registry (ACR, ECR, GCR, etc.).

**GitOps Root**: The `gitops-root` OCI artifact contains all cluster resources - both plain manifests and references to other OCI artifacts. See [oci-artifacts/README.md](oci-artifacts/README.md) for details.

**Infrastructure**: Flux controllers and bootstrap configuration. See [infrastructure/README.md](infrastructure/README.md) for details.

**Notifications**: A webhook logger service prints notification bodies. In production, use Slack, Teams, or other notification providers.

## Requirements

- **kind** - Kubernetes in Docker for local cluster creation
  [https://kind.sigs.k8s.io/docs/user/quick-start/#installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

- **Flux CLI** - GitOps toolkit for Kubernetes
  [https://fluxcd.io/flux/installation/](https://fluxcd.io/flux/installation/)

- **Helm** - Package manager for Kubernetes (required for pushing Helm charts)
  [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)

## Quick Start

1. **Setup cluster and infrastructure**:
   ```bash
   make setup
   ```
   This creates a kind cluster, deploys the registry, installs Flux, and pushes the gitops-root artifact.

2. **Deploy dummy-service** (optional):
   ```bash
   make push-dummy-service
   ```
   Flux automatically reconciles and deploys the service. Test notifications by checking webhook-logger logs.

3. **Deploy dummy-helmrelease** (optional):
   ```bash
   make push-dummy-helmrelease
   # Or with custom version:
   make push-dummy-helmrelease DUMMY_HELM_VERSION=0.2.0
   ```
   Pushes both the Helm chart and HelmRelease manifest as OCI artifacts. Flux automatically reconciles.

4. **Cleanup**:
   ```bash
   make kind-delete
   ```

## Makefile Targets

- `make setup` - Create cluster, install infrastructure, push gitops-root
- `make push-gitops` - Push gitops-root OCI artifact
- `make push-dummy-service` - Push dummy-service OCI artifact
- `make push-dummy-helmrelease` - Push Helm chart and HelmRelease manifest as OCI artifacts (default version: 0.1.0)
- `make push-helm-chart` - Push only the Helm chart OCI artifact
- `make push-helmrelease-manifest` - Push only the HelmRelease manifest OCI artifact
- `make registry-port-forward` - Forward registry port to localhost:5000 (stores PID in /tmp/registry-pf.pid)
- `make stop-port-forward` - Stop registry port-forward (reads PID from /tmp/registry-pf.pid)
- `make kind-delete` - Delete the kind cluster
