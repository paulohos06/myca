#!/bin/bash
# --- Funções de Utilitário ---


# Função para exibir mensagens de erro e sair
error_exit() {
    echo -e "\n[ERRO] $1" >&2 # Redireciona para stderr
    exit 1
}

# Função de ajuda
show_help() {
    echo "MyCA - Inicializa uma nova Autoridade Certificadora Raiz (Root CA)"
    echo "Uso: $0 -name <root_ca_name>"
    echo "Opções:"
    echo "  -name <root_ca_name>  Define o nome da nova root CA (e o nome do diretório)."
    echo "  -h                    Exibe esta mensagem de ajuda."
}

# Função para validar o nome do módulo
validate_module_name() {
    if [[ -z "$1" ]]; then
        show_help
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
