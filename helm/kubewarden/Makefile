CRD_VERSION=1.28.1

install: crd
	helm upgrade --install --wait -n kubewarden kubewarden-controller .


# CRDs are in a different chart
crd:
	helm upgrade --install --wait -n kubewarden --create-namespace kubewarden-crds kubewarden/kubewarden-crds --version ${CRD_VERSION}
