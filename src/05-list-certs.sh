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

listcerts() {
  local ca_name="${1:-}"
	
  # Validação de argumentos obrigatórios
  [[ -z "$ca_name" ]] && error_exit "O nome da CA (-n) é obrigatório."

  # Definição de caminhos
  local base_path="$PARENT_DIR/ca/$ca_name"
  local index_file="$base_path/index.txt"
  
  # 1. Validação de Infraestrutura
  [[ ! -d "$base_path" ]] && error_exit "Estrutura da CA '$ca_name' não encontrada em $base_path"
  [[ ! -f "$index_file" ]] && error_exit "Base de Dados da CA não foi encontrada. Arquivo inexistente: $index_file"

	echo ""
  echo "==============================================================="
	echo "  RELATÓRIO DE CERTIFICADOS DA $ca_name - $(date +'%d/%m/%Y')  "
	echo "==============================================================="

	# --- CERTIFICADOS VÁLIDOS ---
	echo -e "\n[+] CERTIFICADOS VÁLIDOS (ATIVOS):"
	echo "---------------------------------------------------------"
	printf "%-10s | %-15s | %s\n" "SERIAL" "EXPIRA EM" "SUBJECT (DN)"
	awk -F'\t' '$1 == "V" { printf "%-10s | %-15s | %s\n", $4, $2, $6 }' "$index_file"

	# --- CERTIFICADOS REVOGADOS ---
	echo -e "\n[-] CERTIFICADOS REVOGADOS:"
	echo "---------------------------------------------------------"
	printf "%-10s | %-15s | %s\n" "SERIAL" "REVOGADO EM" "SUBJECT (DN)"
	awk -F'\t' '$1 == "R" { printf "%-10s | %-15s | %s\n", $4, $3, $6 }' "$index_file"

	echo -e "\n=============================================================\n"
}

# --- Parsing de Argumentos ---
CA_NAME=""

while getopts "n:" opt; do
  case $opt in
    n) CA_NAME="$OPTARG" ;;
    *) showhelp ;;
  esac
done

# Execução principal
listcerts "$CA_NAME"
