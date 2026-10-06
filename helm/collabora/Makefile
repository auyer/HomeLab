SHELL := /bin/bash
NAMESPACE ?= collabora

upgrade:
	helm upgrade --install -n $(NAMESPACE) collabora . --create-namespace

uninstall:
	helm uninstall -n $(NAMESPACE) collabora


secrets/create:
	@echo "Enter USERNAME:" && read USERNAME && \
	echo "Enter PASSWORD:" && read -s PASSWORD && echo && \
	kubectl create secret generic collabora-admin-creds \
		-n $(NAMESPACE) \
		--from-literal=USERNAME=$$USERNAME \
		--from-literal=PASSWORD=$$PASSWORD \
		--dry-run=client -o yaml | \
	kubeseal --format yaml -o yaml > templates/sealed-collabora-creds.yaml && \
	echo "Created templates/sealed-collabora-creds.yaml"

secrets/deploy:
	kubectl apply -f templates/sealed-collabora-creds.yaml
