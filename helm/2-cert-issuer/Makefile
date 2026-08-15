NAMESPACE ?= cert-manager

upgrade:
	helm upgrade --install cert-issuer . --namespace cert-manager --create-namespace

secrets/create:
	@echo "Enter CF_API_TOKEN:" && read KEY && \
	kubectl create secret generic cloudflare-api-token-secret \
		-n $(NAMESPACE) \
		--from-literal=CF_API_TOKEN=$$KEY \
		--dry-run=client -o yaml | \
	kubeseal --format yaml -o yaml > templates/sealed_secret.yaml && \
	echo "Created templates/sealed_secret.yaml"
