SHELL := /bin/bash
NAMESPACE ?= observability

# This chart has a special installation setup.

upgrade:
	helm upgrade -n $(NAMESPACE) lgtm . --create-namespace --dependency-update \
		--set lgtm.collectors.enabled=true

install:
	helm install -n $(NAMESPACE) lgtm . --create-namespace --dependency-update \
		--set lgtm.collectors.enabled=false

uninstall:
	helm uninstall -n $(NAMESPACE) lgtm

secrets/create:
	@echo "Enter AWS_ACCESS_KEY_ID:" && read KEY && \
	echo "Enter AWS_SECRET_ACCESS_KEY:" && read -s SECRET && echo && \
	kubectl create secret generic lgtm-loki-s3 \
		-n $(NAMESPACE) \
		--from-literal=AWS_ACCESS_KEY_ID=$$KEY \
		--from-literal=AWS_SECRET_ACCESS_KEY=$$SECRET \
		--dry-run=client -o yaml | \
	kubeseal --format yaml -o yaml > templates/sealed-loki-s3.yaml && \
	echo "Created templates/sealed-loki-s3.yaml"

secrets/deploy:
	kubectl apply -f templates/sealed-loki-s3.yaml
