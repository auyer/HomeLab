upgrade:
	helm dependency build
	helm upgrade --install rancher . --namespace cattle-system \
		--create-namespace

uninitall:
	helm uninstall -n cattle-system rancher
