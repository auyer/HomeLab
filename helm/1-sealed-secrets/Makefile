KUBESEAL_VERSION=0.38.4

# I wish this was a helm chart ;P
upgrade:
	kubectl apply -f https://github.com/bitnami/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/controller.yaml

client:
	curl -OL "https://github.com/bitnami/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
	tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
	sudo install -m 755 kubeseal /usr/local/bin/kubeseal
