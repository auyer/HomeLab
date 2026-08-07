# no customizations on top
install:
	helm install --wait -n kubewarden --create-namespace admission-controller kubewarden/admission-controller

uninstall:
	helm uninstall -n kubewarden admission-controller

