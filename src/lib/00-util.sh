#!/bin/bash
# --- Funções de Utilitário ---


# Função para exibir mensagens de erro e sair

error_exit() {
    echo -e "\n[ERRO] $1" >&2 # Redireciona para stderr
    exit 1
}

showhelp() {
	echo -e "[WARN] Show Help"
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

formatstring() {
    local input="$1"

    # 1. Remove espaços no início e no final (trim)
    # 2. Converte para minúscula
    # 3. Remove acentos usando iconv (converte para ASCII puro)
    # 4. Remove todos os espaços internos

    echo "$input" | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
        tr '[:upper:]' '[:lower:]' | \
        iconv -f UTF-8 -t ASCII//TRANSLIT | \
        tr -d '[:space:]'
        #sed 's/[^a-z0-9]//g'
}
