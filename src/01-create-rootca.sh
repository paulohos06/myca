#!/bin/bash

# --- Configurações de Segurança ---
# -e: sai em erro, -u: erro em variáveis não definidas, -o pipefail: captura erro em pipes
set -euo pipefail

# --- Variáveis Globais e Dependências ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"
CA_BASE_DIR="$PARENT_DIR/ca"

UTILS="$SRC_DIR/libs/utils.sh"
[[ -f "$UTILS" ]] && source "$UTILS" || {
  echo "[ERRO] Função de utilitários não encontrados em $UTILS." >&2
  exit 1
}

# --- Funções Internas ---
setup_structure() {
  local ca_name="$1"
  local pki_subdirs=("certs" "conf" "crl" "csr" "newcerts" "private")
  echo "[+] Criando estrutura de diretórios em $ca_name..."
    
  for dir in "${pki_subdirs[@]}"; do
    mkdir -p "$ca_name/$dir"
  done

  # Arquivos de controle do OpenSSL
  chmod 700 "$ca_name/private"
  touch "$ca_name/index.txt"
  touch "$ca_name/serial"
}

configure_ca() {
  local ca_name="$1"
  local path="$2"
  local target_conf="$path/conf/$ca_name.cnf"

  echo "[+] Configurando arquivo OpenSSL para $ca_name..."
    
  # Valida template original
  [[ ! -f "$SRC_DIR/conf/ca.cnf" ]] && error_exit "Template conf/ca.cnf não encontrado."

  # Cópia dos arquivos de configuração da CA
  mkdir -p "$path/conf/profiles" && cp -r "$SRC_DIR/conf/profiles/"*.cnf "$path/conf/profiles"
  sed -e "s|/pathdir/|$path|g" \
      -e "s|ca.key.pem|$ca_name.key.pem|g" \
      -e "s|ca.cert.pem|$ca_name.cert.pem|g" \
      "$SRC_DIR/conf/ca.cnf" > "$target_conf"
}

newrootca() {
  local name_input="${1:-}"
	local ca_name=$(formatstring "$name_input")
  local newca_dir="$CA_BASE_DIR/$ca_name"

  # Validações Iniciais
  [[ -z "$ca_name" ]] && { error_exit "Informe o nome da CA.."; }
  [[ -d "$newca_dir" ]] && error_exit "A CA informada já existe."

  echo "[+] Iniciando criação da Root CA: $ca_name"
  # 1. Preparar Diretórios
  setup_structure "$newca_dir"

  # 2. Configurar Arquivos
  configure_ca "$ca_name" "$newca_dir"

  # 3. Gerar Chave Privada (AES-256)
  local key_file="$newca_dir/private/$ca_name.key.pem"
  echo "[+] Gerando chave privada RSA 4096 bits..."
  openssl genrsa -aes256 -out "$key_file" 4096
  chmod 400 "$key_file"

  # 4. Gerar Certificado Autoassinado (Root)
  local cert_file="$newca_dir/certs/$ca_name.cert.pem"
  echo "[+] Gerando certificado Root (3650 dias)..."
  openssl req -config "$newca_dir/conf/$ca_name.cnf" \
      -key "$key_file" \
      -new -x509 -days 3650 -sha256 \
      -out "$cert_file"
  
	echo -e "\n[OK] Sucesso: CA '$ca_name' criada com sucesso."
  echo -e "[OK] Localização: $newca_dir"
}

# --- Parsing de Argumentos ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  MODULE_NAME=""

  while getopts "n:h" opt; do
    case $opt in
        n) MODULE_NAME="$OPTARG" ;;
        h) showhelp ;;
        *) showhelp ;;
    esac
  done
fi
newrootca "$MODULE_NAME"
