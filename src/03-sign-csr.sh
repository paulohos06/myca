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

newcert() {
  local ca_name="${1:-}"
  local domain_name="${2:-}"
  local validation="${3:-EV}"
  local policy=""
	local cyear=$(date +%Y)
  local nyear=$(date --date '1 year' "+%Y")

  # Validação de argumentos obrigatórios
  [[ -z "$ca_name" ]] && error_exit "O nome da CA (-n) é obrigatório."
  [[ -z "$domain_name" ]] && error_exit "O domínio (-d) é obrigatório."

  # Definição de caminhos
  local base_path="$PARENT_DIR/ca/$ca_name"
  local csr_dir="$base_path/csr/$domain_name"
  local new_cert_dir="$base_path/certs/$domain_name"
  local ca_conf_file="$base_path/conf/$ca_name.cnf"
  local new_cert_file="$new_cert_dir/${domain_name}_${cyear}-${nyear}.cert.pem"
  
  # 1. Validação de Infraestrutura
  [[ ! -d "$base_path" ]] && error_exit "Estrutura da CA '$ca_name' não encontrada em $base_path"
  [[ ! -f "$ca_conf_file" ]] && error_exit "Arquivo de config da CA não encontrado: $ca_conf_file"

  # 2. Busca pelo CSR (Melhorada para evitar 'ls')
  local csr_file=""
  if [[ -d "$csr_dir" ]]; then
    # Pega o arquivo .csr.pem mais recente de forma segura
    for f in "$csr_dir"/*.csr.pem; do
      [[ -e "$f" ]] || continue
      csr_file="$f" # No loop, o último arquivo (alfabético/recente) permanece
    done
  fi

  [[ -z "$csr_file" ]] && error_exit "Nenhum arquivo CSR encontrado em $csr_dir"

  # 3. Definição de Política (Normalização)
  case "${validation^^}" in
    DV) policy="policy_dv" ;;
    OV) policy="policy_ov" ;;
    EV) policy="policy_ev" ;;
    *)  policy="policy_ev" ; echo "[WARN] Validação desconhecida. Usando fallback: EV" ;;
  esac

  # 4. Preparação do diretório de saída
  mkdir -p "$new_cert_dir"

  # 5. Assinatura do Certificado
  echo "[INFO] Usando CSR: $(basename "$csr_file")"
  echo "[INFO] Assinando com a CA '$ca_name' sob política '$policy'..."
  
  # Uso do 'batch' para não pedir confirmação manual se necessário
  # -notext reduz o tamanho do arquivo removendo a versão em texto legível
  openssl ca -batch -days 365 \
    -in "$csr_file" \
    -out "$new_cert_file" \
    -config "$ca_conf_file" \
    -policy "$policy" \
    -rand_serial

  echo "[OK] Certificado gerado com sucesso em: $new_cert_file"
}

# --- Parsing de Argumentos ---
CA_NAME=""
CSR_NAME=""
VALIDATION="EV"

while getopts "n:d:v:" opt; do
  case $opt in
    n) CA_NAME="$OPTARG" ;;
    d) CSR_NAME="$OPTARG" ;;
    v) VALIDATION="$OPTARG" ;;
    *) showhelp ;;
  esac
done

# Execução principal
newcert "$CA_NAME" "$CSR_NAME" "$VALIDATION"
