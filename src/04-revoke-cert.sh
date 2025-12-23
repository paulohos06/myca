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

revokecert() {
  local ca_name="${1:-}"
  local serial_number="${2:-}"
	
  # Validação de argumentos obrigatórios
  [[ -z "$ca_name" ]] && error_exit "O nome da CA (-n) é obrigatório."
  [[ -z "$serial_number" ]] && error_exit "O número de série (-s) é obrigatório."

  # Definição de caminhos
  local base_path="$PARENT_DIR/ca/$ca_name"
  local certs_dir="$base_path/certs"
  local ca_conf_file="$base_path/conf/$ca_name.cnf"
  
  # 1. Validação de Infraestrutura
  [[ ! -d "$base_path" ]] && error_exit "Estrutura da CA '$ca_name' não encontrada em $base_path"
  [[ ! -f "$ca_conf_file" ]] && error_exit "Arquivo de config da CA não encontrado: $ca_conf_file"

  # 2. Definição de Política (Normalização)
  echo "[+] Iniciando busca pelo Serial: $serial_number"
	find "$certs_dir" -type f -name "*.cert.pem" | while read -r cert; do
    # Extrai o serial do arquivo atual (em maiúsculas para evitar erro de comparação)
    serialn=$(openssl x509 -in "$cert" -noout -serial | cut -d'=' -f2 | tr '[:lower:]' '[:upper:]')
		if [[ "$serialn" == "${serial_number^^}"  ]]; then
		  echo "[+] Certificado encontrado em: $cert"
			echo "[+] Iniciando a revogação..."
			openssl ca -config "$ca_conf_file" -revoke "$cert"

		  if [ $? -eq 0 ]; then
        echo "[OK] Revogação concluída. Atualizando CRL..."
				openssl ca -config "$ca_conf_file" -gencrl -out "$base_path/crl/$ca_name.crl"
				exit 0
			else
			  error_exit "Não foi possível revogar o certificado."
				exit 1
			fi
		fi
	done

}

# --- Parsing de Argumentos ---
CA_NAME=""
SERIALN=""

while getopts "n:s:" opt; do
  case $opt in
    n) CA_NAME="$OPTARG" ;;
    s) SERIALN="$OPTARG" ;;
    *) showhelp ;;
  esac
done

# Execução principal
revokecert "$CA_NAME" "$SERIALN"
