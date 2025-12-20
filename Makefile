# Configurações do Makefile
SHELL := /bin/bash
.DEFAULT_GOAL := help

# Cores para saída no terminal
YELLOW := \033[1;33m
RESET  := \033[0m

# --- Variáveis com Valores Padrão ---
val ?= EV
ca_dir := ./ca

# --- Macros de Validação ---
# Verifica se a variável foi definida, caso contrário interrompe com erro.
check_var = $(if $(strip $($1)),,$(error Erro: A variável '$1' não foi definida. Use '$1=<valor>'))

.PHONY: help setup-ca create-csr sign-csr

help: ## Exibe esta mensagem de ajuda
	@echo -e "$(YELLOW)Comandos disponíveis:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup-ca: ## Inicializa uma nova AC Raiz. Ex: make setup-ca ca=minha-ca
	@$(call check_var,ca)
	@echo -e "$(YELLOW)Iniciando setup da CA: $(ca)...$(RESET)"
	bash src/01-create-rootca.sh -n $(ca)

create-csr: ## Gera chave privada e CSR. Ex: make create-csr ca=minha-ca domain=exemplo.com [val=DV]
	@$(call check_var,ca)
	@$(call check_var,domain)
	@echo -e "$(YELLOW)Gerando CSR para $(domain) usando CA $(ca)...$(RESET)"
	bash src/02-create-csr.sh -n $(ca) -d $(domain) -v $(val)

sign-csr: ## Assina uma CSR existente. Ex: make sign-csr ca=minha-ca domain=exemplo.com [val=DV]
	@$(call check_var,ca)
	@$(call check_var,domain)
	@echo -e "$(YELLOW)Assinando certificado para $(domain) com a CA $(ca)...$(RESET)"
	bash src/03-sign-csr.sh -n $(ca) -d $(domain) -v $(val)

remove-ca:
	@$(call check_var,ca)
	@echo -e "$(RED)[ATENÇÃO]: Você está prestes a excluir permanentemente a CA '$(ca)' e todas as suas chaves!$(RESET)"
	@read -p "Tem certeza que deseja continuar? [y/N] " ans && [ $${ans:-N} = y ] || (echo "Operação cancelada."; exit 1)
	rm -rf $(ca_dir)/$(ca)/
	@echo -e "CA '$(ca)' removida com sucesso."

clean-ca: ## (Opcional) Remove arquivos temporários de uma CA específica
	@$(call check_var,ca)
	@echo -e "$(YELLOW)Limpando arquivos da CA $(ca)...$(RESET)"
	rm -rf $(ca_dir)/$(ca)/csr/*
