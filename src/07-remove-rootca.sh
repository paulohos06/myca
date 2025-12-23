#!/bin/bash

# Configurações de segurança do shell
set -euo pipefail

# --- Variáveis Globais ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"
UTILS="$SRC_DIR/lib/00-util.sh"

# --- Carregamento de Dependências ---
if [[ -f "$UTILS" ]]; then
  # shellcheck source=/dev/null
  source "$UTILS"
else
  echo "Erro: Arquivo de utilidades não encontrado em $UTILS." >&2
  exit 1
fi

removeca() {
  local ca_name="${1:-}"

  # Validação de argumentos obrigatórios
  [[ -z "$ca_name" ]] && error_exit "O nome da CA (-n) é obrigatório."

  # Definição de caminhos
  local base_path="$PARENT_DIR/ca/$ca_name"
  
  # 1. Validação de Infraestrutura
  [[ ! -d "$base_path" ]] && error_exit "Estrutura da CA '$ca_name' não encontrada em $PARENT_DIR/ca"

  # 2. Remoção da CA
  rm -rf "$base_path"

	if [[ $? -eq 0 ]]; then
    echo -e "\n[OK] AC '$ca_name' removida com sucesso."
		exit 0
	else
	  error_exit "Não foi possível remover a CA '$ca_name'"
		exit 1
	fi
}

# --- Parsing de Argumentos ---
CA_NAME=""

while getopts "n:" opt; do
  case $opt in
    n) CA_NAME="$OPTARG" ;;
    *) echo "Uso: $0 -n <nome_ca>" ; exit 1 ;;
  esac
done

# Execução principal
removeca "$CA_NAME"
