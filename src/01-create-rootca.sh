#!/bin/bash

# --- Configurações de Segurança ---
# -e: sai em erro, -u: erro em variáveis não definidas, -o pipefail: captura erro em pipes
set -euo pipefail

# --- Variáveis Globais e Dependências ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"
CA_BASE_DIR="$PARENT_DIR/ca"
PKI_SUBDIRS=("certs" "conf" "crl" "csr" "newcerts" "private")

UTILS="$SRC_DIR/lib/00-util.sh"
if [[ -f "$UTILS" ]]; then
    # shellcheck source=/dev/null
    source "$UTILS"
else
    echo "Erro: Utilitários não encontrados em $UTILS." >&2
    exit 1
fi

# --- Funções Internas ---

setup_structure() {
    local module_path="$1"
    echo "[+] Criando estrutura de diretórios em $module_path..."
    
    for dir in "${PKI_SUBDIRS[@]}"; do
        mkdir -p "$module_path/$dir"
    done

    # Arquivos de controle do OpenSSL
    chmod 700 "$module_path/private"
    touch "$module_path/index.txt"
    if [[ ! -f "$module_path/serial" ]]; then
        echo 1000 > "$module_path/serial"
    fi
}

configure_ca() {
    local name="$1"
    local path="$2"
    local target_conf="$path/conf/$name.cnf"

    echo "[+] Configurando arquivo OpenSSL para $name..."
    
    # Valida template original
    [[ ! -f "$SRC_DIR/conf/ca.cnf" ]] && error_exit "Template conf/ca.cnf não encontrado."

    # Cópia e substituição usando sintaxe portável
    cp -r "$SRC_DIR/conf/profiles" "$path/conf/"
    sed -e "s|/pathdir/|$path|g" \
        -e "s|ca.key.pem|$name.key.pem|g" \
        -e "s|ca.cert.pem|$name.cert.pem|g" \
        "$SRC_DIR/conf/ca.cnf" > "$target_conf"
}

newrootca() {
    local name="${1:-}"
    local module_path="$CA_BASE_DIR/$name"

    # Validações Iniciais
    [[ -z "$name" ]] && { echo "Erro: Nome da AC não fornecido."; usage; }
    [[ -d "$module_path" ]] && error_exit "A AC '$name' já existe em $module_path."

    echo "--- Iniciando criação da Root CA: $name ---"

    # 1. Preparar Diretórios
    setup_structure "$module_path"

    # 2. Configurar Arquivos
    configure_ca "$name" "$module_path"

    # 3. Gerar Chave Privada (AES-256)
    local key_file="$module_path/private/$name.key.pem"
    echo "[+] Gerando chave privada RSA 4096 bits..."
    openssl genrsa -aes256 -out "$key_file" 4096
    chmod 400 "$key_file"

    # 4. Gerar Certificado Autoassinado (Root)
    local cert_file="$module_path/certs/$name.cert.pem"
    echo "[+] Gerando certificado Root (3650 dias)..."
    openssl req -config "$module_path/conf/$name.cnf" \
        -key "$key_file" \
        -new -x509 -days 3650 -sha512 \
        -out "$cert_file"

    echo -e "\n[OK] AC Raiz '$name' pronta."
    echo "Localização: $module_path"
}

# --- Parsing de Argumentos ---
MODULE_NAME=""

while getopts "n:h" opt; do
    case $opt in
        n) MODULE_NAME="$OPTARG" ;;
        h) showhelp ;;
        *) showhelp ;;
    esac
done

newrootca "$MODULE_NAME"
