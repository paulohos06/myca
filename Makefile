# Configurações do Makefile
SHELL := /bin/bash
.DEFAULT_GOAL := help
.SILENT: 

# Cores para saída no terminal
YELLOW := \033[1;33m
RESET  := \033[0m

# --- Variáveis com Valores Padrão ---
val ?= EV
ca_dir := ./ca

# --- Macros de Validação ---
# Verifica se a variável foi definida, caso contrário interrompe com erro.
check_var = $(if $(strip $($1)),,$(error [ERRO]: A variável '$1' não foi definida. Use '$1=<valor>'))

.PHONY: help setup-ca create-csr sign-csr remove-ca revoke-cert

help: ## Exibe esta mensagem de ajuda. Ex: make help
	@echo -e "$(YELLOW)Comandos disponíveis:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

create-rootca: ## Inicializa uma nova AC Raiz. Ex: make create-rootca ca=rootca
	@$(call check_var,ca)
	#@echo -e "$(YELLOW)Iniciando setup da CA: $(ca)...$(RESET)"
	@bash src/01-create-rootca.sh -n $(ca)

create-csr: ## Gera chave privada e CSR. Ex: make create-csr ca=rootca domain=example [val=DV|OV|EV]
	@$(call check_var,ca)
	@$(call check_var,domain)
	#@echo -e "$(YELLOW)Gerando CSR para $(domain) usando CA $(ca)...$(RESET)"
	@bash src/02-create-csr.sh -n $(ca) -d $(domain) -v $(val)

sign-csr: ## Assina uma CSR existente. Ex: make sign-csr ca=rootca domain=example [val=DV|OV|EV]
	@$(call check_var,ca)
	@$(call check_var,domain)
	#@echo -e "$(YELLOW)Assinando certificado para $(domain) com a CA $(ca)...$(RESET)"
	@bash src/03-sign-csr.sh -n $(ca) -d $(domain) -v $(val)

remove-rootca: ## Remove uma CA existente: Ex: make remove-rootca ca=rootca
	@$(call check_var,ca)
	@echo -e "$(YELLOW)[ATENÇÃO]: Você removerá a CA '$(ca)' e todas as suas chaves!$(RESET)"
	@read -p "Tem certeza que deseja continuar? [y/N] " ans && [ $${ans:-N} = y ] || (echo "Operação cancelada."; exit 1)
	@bash src/07-remove-rootca.sh -n $(ca)

revoke-cert: ## Revoga um certificado existente. Ex: make revoke-cert ca=rootca serial=serial-number
	@$(call check_var,ca)
	@$(call check_var,serial)
	@echo -e "$(YELLOW)[ATENÇÃO]: Você revogará o certificado '$(ca)'/'$(serial)'!$(RESET)"
	@read -p "Tem certeza que deseja continuar? [y/N] " ans && [ $${ans:-N} = y ] || (echo "Operação cancelada."; exit 1)
	@bash src/04-revoke-cert.sh -n $(ca) -s $(serial)

list-certs: ## Lista os certificados válidos e revogados da CA. Ex: make list-certs ca=rootca
	@$(call check_var,ca)
	#@echo -e "$(YELLOW)Listagem de Certificados da CA: $(ca)...$(RESET)"
	@bash src/05-list-certs.sh -n $(ca)
	
list-rootca: ## Lista as CAs existentes
	#@echo -e "$(YELLOW)Listagem AC Raiz$(RESET)"
	@bash src/06-list-rootca.sh
