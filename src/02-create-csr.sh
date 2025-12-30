#!/bin/bash

# Configurações de segurança do Bash
set -euo pipefail

# --- Variáveis Globais ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"

UTILS="$SRC_DIR/libs/utils.sh"
[[ -f "$UTILS" ]] && source "$UTILS" || {
  echo "[ERRO] Função de utilitários não encontrados em $UTILS." >&2
  exit 1
}

newcsr() {
    local ca_name="${1:-}"
    local domain_name="${2:-}"
    local validation="${3:-EV}" # Default para EV se vazio
    local cyear=$(date +%Y)
		local nyear=$(date --date '1 year' "+%Y")

    # Validação de parâmetros
    [[ -z "$ca_name" ]] && error_exit "O nome da CA (-n) é obrigatório."
    [[ -z "$domain_name" ]] && error_exit "O domínio (-d) é obrigatório."

    # Definição de caminhos
    local base_path="$PARENT_DIR/ca/$ca_name"
    local csr_dir="$base_path/csr/$domain_name"
    local key_dir="$base_path/private/$domain_name"
    local new_key_file="$key_dir/$domain_name.key.pem"
    local new_csr_file="$csr_dir/${domain_name}_${cyear}-${nyear}.csr.pem"
    local new_conf_file="$csr_dir/$domain_name.cnf"

    # 1. Validação de infraestrutura
    [[ ! -d "$base_path" ]] && error_exit "Estrutura da CA '$ca_name' não encontrada em $base_path"

    # 2. Preparação de Diretórios
    mkdir -p "$key_dir" "$csr_dir"
    chmod 700 "$key_dir"

    # 3. Geração da Chave Privada (apenas se não existir)
    if [[ ! -f "$new_key_file" ]]; then
        echo "[INFO] Gerando chave privada RSA 2048 bits..."
        openssl genrsa -out "$new_key_file" 2048
        chmod 400 "$new_key_file"
    else
      echo "[WARN] Chave privada já existe em $new_key_file. Pulando geração."
    fi

    # 4. Seleção do Template de Configuração
    local template_conf=""
    case "${validation^^}" in # Converte para maiúsculas
        DV) template_conf="$SRC_DIR/conf/profiles/conf-scripts/conf-dv.cnf" ;;
        OV) template_conf="$SRC_DIR/conf/profiles/conf-scripts/conf-ov.cnf" ;;
        EV) template_conf="$SRC_DIR/conf/profiles/conf-scripts/conf-ev.cnf" ;;
        *)  error_exit "Tipo de validação '$validation' inválido. Use DV, OV ou EV." ;;
    esac

    [[ ! -f "$template_conf" ]] && error_exit "Template de configuração não encontrado: $template_conf"

    # 5. Customização do arquivo de configuração (Sem sed -i para maior compatibilidade)
    echo "[INFO] Preparando arquivo de configuração OpenSSL..."
    sed "s/domain_name.com.br/$domain_name.brb.com.br/g" "$template_conf" > "$new_conf_file"

    # 6. Geração da CSR
    echo "[INFO] Criando a CSR para $domain_name..."
    if openssl req -new -key "$new_key_file" -out "$new_csr_file" -config "$new_conf_file"; then
				new_domain_name="$(openssl req -in "$new_csr_file" -noout -subject | sed -n 's/.*CN=\([^,]*\).*/\1/p')"
				if [[ "$domain_name.brb.com.br" != "$new_domain_name" ]]; then
          echo "CN diferentes"
				fi
        echo "[OK] Sucesso! CSR gerada em: $new_csr_file"
    else
        error_exit "Falha na execução do OpenSSL ao gerar CSR."
    fi
}

# --- Parsing de Argumentos ---
CA_NAME=""
DOMAIN_NAME=""
VAL_LEVEL="EV"

while getopts "n:d:v:h" opt; do
    case $opt in
        n) CA_NAME="$OPTARG" ;;
        d) DOMAIN_NAME="$OPTARG" ;;
        v) VAL_LEVEL="$OPTARG" ;;
        h) showhelp ;;
        *) showhelp ;;
    esac
done

# Execução
newcsr "$CA_NAME" "$DOMAIN_NAME" "$VAL_LEVEL"
