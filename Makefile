
.PHONY: setup-ca create-csr sign-csr

setup-ca:
	bash src/01-create-root-ca.sh -n $(ca)

create-csr:
	bash src/02-create-csr.sh -n $(ca) -d $(domain) -v $(val)

sign_csr:
	bash src/03-sign-csr.sh -n $(ca) -d $(domain) -v $(val)
