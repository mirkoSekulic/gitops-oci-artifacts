# Infrastructure

Core infrastructure manifests for the GitOps setup.

## registry.yaml

Local OCI registry deployment and service. Used to store and serve Flux OCI artifacts.

## flux-install.yaml

Flux controllers and CRDs. Contains all necessary components for Flux to run (source-controller, kustomize-controller, etc.).

Generated with `flux install --export` to pin the Flux version (v2.7.1).

## flux-bootstrap.yaml

Bootstrap configuration that points Flux to the gitops-root OCI artifact. Contains the OCIRepository and Kustomization resources that start the GitOps reconciliation loop.
