#!/bin/bash
# --- Funções de Utilitário ---


# Função para exibir mensagens de erro e sair
error_exit() {
    echo -e "\n[ERRO] $1" >&2 # Redireciona para stderr
    exit 1
}

# Função de ajuda
show_help() {
  echo "MyCA - Autoridade Certificadora Interna (RootCA)"
	
	if [[ "$1" == "create_root" ]]; then
		echo "Opções:"
		echo "   -n <ca_name>      Informa qual CA assinará o certificado."
    echo "   -h                Exibe esta mensagem de ajuda."
	elif [[ "$1" == "sign_csr" ]]; then
    echo "Uso: $0 -n <ca_name> -c <csr_name>"
		echo "Opções:"
		echo "   -n <ca_name>      Informa qual CA assinará o certificado."
		echo "   -d <domain_name>  Informa qual o nome do domínio da CSR."
    echo "   -h                Exibe esta mensagem de ajuda."
	fi
}

# Função para validar o nome do módulo
validate_module_name() {
    if [[ -z "$1" ]]; then
        show_help "create_root"
        error_exit "Erro: O nome do módulo deve ser fornecido com a opção -name."
    fi
    # Adicionar aqui verificação de caracteres inválidos, se necessário (ex: regex)
    # if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then error_exit "Nome do módulo inválido..."
    return 0
}

get_script_path() {
  local script_path
  local script_dir

  # 1. Encontra o diretório real onde o script está (trata symbolic links)
  script_path="$(readlink -f "${BASH_SOURCE[0]}")"

  # 2. Obtém o diretório do script (o diretório pai do SCRIPT_PATH)
  script_dir="$(dirname "$script_path")"

  # Retorna o valor do diretório anterior
  echo "$(dirname "$script_dir")"
}
