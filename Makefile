ca_name=rootca

.PHONY: setup-ca

setup-ca:
	bash src/01-create-root-ca.sh -n $(ca_name)
