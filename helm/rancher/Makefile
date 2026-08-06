upgrade:
	echo "Off, my cluster needs more resources to run this :("
	# helm dependency build
	# helm upgrade --install rancher . --namespace cattle-system \
	# 	--create-namespace

uninitall:
	helm uninstall -n cattle-system rancher
