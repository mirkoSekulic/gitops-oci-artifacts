CLUSTER_NAME ?= gitops-oci

.PHONY: kind-create
kind-create:
	kind create cluster --name $(CLUSTER_NAME)

.PHONY: kind-delete
kind-delete:
	kind delete cluster --name $(CLUSTER_NAME)

.PHONY: registry-install
registry-install:
	kubectl apply -f registry.yaml

.PHONY: flux-install
flux-install:
	flux install

.PHONY: apply
apply:
	kubectl apply -f flux-oci.yaml

.PHONY: push-gitops
push-gitops:
	flux push artifact oci://localhost:5000/gitops-root:dev \
		--path=./gitops-root \
		--source="$$(git config --get remote.origin.url)" \
		--revision="$$(git branch --show-current)/$$(git rev-parse HEAD)"

.PHONY: registry-port-forward
registry-port-forward:
	kubectl port-forward -n registry svc/registry 5000:5000 > /tmp/registry-pf.log 2>&1 & echo $$! > /tmp/registry-pf.pid

.PHONY: stop-port-forward
stop-port-forward:
	@if [ -f /tmp/registry-pf.pid ]; then kill $$(cat /tmp/registry-pf.pid) 2>/dev/null || true; rm /tmp/registry-pf.pid; echo "Port-forward stopped"; else echo "No port-forward running"; fi

.PHONY: setup
setup: kind-create registry-install
	@echo "Waiting for registry pod to be created..."
	@sleep 5
	@echo "Waiting for registry to be ready..."
	kubectl wait --for=condition=ready pod -l app=registry -n registry --timeout=120s
	@echo "Starting port-forward in background..."
	$(MAKE) registry-port-forward
	@sleep 3
	@echo "Pushing gitops-root to registry..."
	$(MAKE) push-gitops
	@echo "Installing Flux..."
	$(MAKE) flux-install
	@echo "Applying Flux OCI configuration..."
	$(MAKE) apply
	@echo "Setup complete! Run 'make stop-port-forward' to stop the registry port-forward."
