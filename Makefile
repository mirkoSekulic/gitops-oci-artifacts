CLUSTER_NAME ?= gitops-oci
DUMMY_HELM_VERSION ?= 0.1.0

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

.PHONY: push-helm-chart
push-helm-chart:
	helm package ./oci-artifacts/dummy-helmrelease/helm-chart -d /tmp --version $(DUMMY_HELM_VERSION)
	helm push /tmp/dummy-helmrelease-$(DUMMY_HELM_VERSION).tgz oci://localhost:5000/helm-charts
	rm /tmp/dummy-helmrelease-$(DUMMY_HELM_VERSION).tgz

.PHONY: push-helmrelease-manifest
push-helmrelease-manifest:
	mkdir -p /tmp/dummy-helmrelease-manifest
	sed 's/__VERSION__/$(DUMMY_HELM_VERSION)/g' ./oci-artifacts/dummy-helmrelease/helmrelease/helmrelease.yaml > /tmp/dummy-helmrelease-manifest/helmrelease.yaml
	flux push artifact oci://localhost:5000/dummy-helmrelease:dev \
		--path=/tmp/dummy-helmrelease-manifest \
		--source="$$(git config --get remote.origin.url)" \
		--revision="$$(git branch --show-current)/$$(git rev-parse HEAD)"
	rm -rf /tmp/dummy-helmrelease-manifest

.PHONY: push-dummy-helmrelease
push-dummy-helmrelease: push-helm-chart push-helmrelease-manifest

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
