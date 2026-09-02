upgrade:
	helm upgrade --install descheduler --namespace kube-system descheduler/descheduler -f values.yaml

repo:
	helm repo add descheduler https://kubernetes-sigs.github.io/descheduler/

uninstall:
	helm uninstall descheduler --namespace kube-system
