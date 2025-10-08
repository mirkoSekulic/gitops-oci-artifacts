# OCI Artifacts

This directory contains Flux OCI artifacts that are pushed to the registry and deployed via GitOps.

## gitops-root

The root GitOps artifact that contains all cluster resources. It can include:
- **Plain manifests**: Direct Kubernetes resources (e.g., webhook-logger deployment, namespaces)
- **OCI references**: References to other OCI artifacts for modular deployments (e.g., dummy-service)

This is the entry point that Flux reconciles from the registry.

## dummy-service

An example application packaged as a separate OCI artifact. Contains all Kubernetes manifests needed to deploy the dummy service.

This demonstrates how to modularize deployments - the gitops-root references this artifact by tag. To update the dummy-service, simply push a new version with the configured tag - no need to redeploy gitops-root.
