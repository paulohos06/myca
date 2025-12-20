#!/bin/bash
# 03-create-csr.sh -n nome_ca -c nome_csr

# --- Variáveis Globais ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"

# --- Funções de Utilitário ---
UTILS="$SRC_DIR/lib/00-util.sh"
if [[ -f "$UTILS" ]]; then
  source "$UTILS"
else
  echo "Erro: Arquivo de utilidades não encontrado em $UTILS." >&2
  exit 1
fi

newcsr() {
  local ca_name="$1"
  local domain_name="$2"
	local valtype="$3"
	local conf_file=""
	local datet="$(date +"%Y%m")"

  # Definição de caminhos para facilitar a manutenção
  local base_path="$PARENT_DIR/ca/$ca_name"
  local csr_dir="$base_path/csr/$domain_name"
  local key_dir="$base_path/private/$domain_name"
  local new_key_file="$base_path/private/$domain_name/$domain_name.key.pem"
  local new_csr_file="$base_path/csr/$domain_name/$domain_name.csr.pem"
	local new_conf_file="$base_path/csr/$domain_name/$domain_name.cnf"

  if [[ -z $ca_name  ]]; then
	  show_help "sign_csr"
    error_exit "O nome da CA que assinará o certificado deve ser fornecido com a opção -n."
	fi

	if [[ -z $domain_name  ]]; then
	  show_help "sign_csr"
    error_exit "O domínio deve ser fornecido com a opção -d."
	fi
  
  # 1. Validação da CA
  if [[ ! -d "$base_path" ]]; then
    error_exit "CA '$ca_name' não encontrada em $base_path"
    return 1
  fi

  # 2. Criação da chave privada
  if [[ ! -d "$key_dir" ]]; then
	  echo "[+] Criando o diretório da chave privada."
		mkdir -p "$key_dir"
	fi

  if [[ ! -f "$new_key_file" ]]; then
	  echo "[+] Criando a chave chave privada."
	  openssl genrsa -out "$new_key_file" 2048
	fi
  
  # 3. Criação da CSR
	if [[ "$valtype" == "DV"  ]]; then 
	  conf_file="$SRC_DIR/conf/profiles/conf-scripts/conf-dv.cnf"
	elif [[ "$valtype" == "OV"  ]]; then 
	  conf_file="$SRC_DIR/conf/profiles/conf-scripts/conf-ov.cnf"
	else 
	  conf_file="$SRC_DIR/conf/profiles/conf-scripts/conf-ev.cnf"
	fi

  if [[ ! -d "$csr_dir" ]]; then
    echo "[+] Criando o diretório da CSR."
    mkdir -p "$csr_dir"
  fi

	cp -r "$conf_file" "$new_conf_file" || error_exit "Falha ao copiar o arquivo de configuração."
	sed -i \
		-e "s|domain_name.com.br|$domain_name.brb.com.br|" \
		"$new_conf_file"

  # 3. Criação da CSR
  echo "[+] Criando a CSR ..."
  
  openssl req -new  \
		-key "$new_key_file" \
		-out "$new_csr_file" \
	  -config "$new_conf_file"

  # 5. Verificação de Sucesso
  if [[ $? -eq 0 ]]; then
    echo "[V] Sucesso! CSR gerada em: $csr_dir"
  else
    error_exit "Não foi possível gerar a CSR para o '$domain_name'."
    return 1
  fi
}

# Usa getopts para analisar as opções da linha de comando
while getopts "n:d:v:" opt; do
  case $opt in
    n)
      CA_NAME="$OPTARG"
      ;;
    d)
      DOMAIN_NAME="$OPTARG"
      ;;
    v)
      VAL_LEVEL="$OPTARG"
			;;
    \?)
      echo "Opção inválida: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "A opção -$OPTARG requer um argumento." >&2
      exit 1
      ;;
  esac
done

# Chama a função principal com o nome do módulo obtido
newcsr "$CA_NAME" "$DOMAIN_NAME" "$VAL_LEVEL"
