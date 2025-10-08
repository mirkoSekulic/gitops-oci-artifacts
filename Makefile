CLUSTER_NAME ?= gitops-oci

.PHONY: kind-create
kind-create:
	kind create cluster --name $(CLUSTER_NAME)

.PHONY: kind-delete
kind-delete:
	kind delete cluster --name $(CLUSTER_NAME)

.PHONY: infrastructure-apply
infrastructure-apply:
	kubectl apply -f infrastructure/registry.yaml
	kubectl wait --for=condition=available --timeout=120s deployment/registry -n registry
	kubectl wait --for=condition=ready --timeout=120s pod -l app=registry -n registry
	kubectl apply -f infrastructure/flux-install.yaml
	kubectl wait --for condition=established --timeout=60s crd/kustomizations.kustomize.toolkit.fluxcd.io crd/ocirepositories.source.toolkit.fluxcd.io
	kubectl apply -f infrastructure/flux-bootstrap.yaml

.PHONY: push-gitops
push-gitops:
	flux push artifact oci://localhost:5000/gitops-root:dev \
		--path=./oci-artifacts/gitops-root \
		--source="$$(git config --get remote.origin.url)" \
		--revision="$$(git branch --show-current)/$$(git rev-parse HEAD)"

.PHONY: push-dummy-service
push-dummy-service:
	flux push artifact oci://localhost:5000/dummy-service:dev \
		--path=./oci-artifacts/dummy-service \
		--source="$$(git config --get remote.origin.url)" \
		--revision="$$(git branch --show-current)/$$(git rev-parse HEAD)"

.PHONY: registry-port-forward
registry-port-forward:
	kubectl port-forward -n registry svc/registry 5000:5000 > /tmp/registry-pf.log 2>&1 & echo $$! > /tmp/registry-pf.pid

.PHONY: stop-port-forward
stop-port-forward:
	@if [ -f /tmp/registry-pf.pid ]; then kill $$(cat /tmp/registry-pf.pid) 2>/dev/null || true; rm /tmp/registry-pf.pid; echo "Port-forward stopped"; else echo "No port-forward running"; fi

.PHONY: setup
setup: kind-create infrastructure-apply
	@echo "Starting port-forward in background..."
	$(MAKE) registry-port-forward
	@sleep 5
	@echo "Pushing gitops-root to registry..."
	$(MAKE) push-gitops
	@echo "Setup complete! Run 'make stop-port-forward' to stop the registry port-forward."
