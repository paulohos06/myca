#!/bin/bash
# make sign ca_name=brbca-mtls csr_name=bxblue
# 02-sign-csr.sh -n nome_ca -c nome_csr -v validation_type

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

newcert() {
  local ca_name="$1"
  local domain_name="$2"
	local validation="$3"
	local policy=""

  if [[ -z $ca_name  ]]; then
	  show_help "sign_csr"
    error_exit "O nome da CA que assinará o certificado deve ser fornecido com a opção -n."
	fi

	if [[ -z $domain_name  ]]; then
	  show_help "sign_csr"
    error_exit "O domínio deve ser fornecido com a opção -d."
	fi
  
  # Definição de caminhos para facilitar a manutenção
  local base_path="$PARENT_DIR/ca/$ca_name"
  local csr_dir="$base_path/csr/$domain_name"
	local new_cert_dir="$base_path/certs/$domain_name"
  local ca_cert="$base_path/certs/$ca_name.cert.pem"
  local csr_file="$base_path/csr/$domain_name/$domain_name.csr.pem"
  local ca_conf_file="$PARENT_DIR/ca/$ca_name/conf/$ca_name.cnf"
  local new_cert_file="$base_path/certs/$domain_name/$domain_name.cert.pem"
	
  # 1. Validação da CA
  if [[ ! -d "$base_path" ]]; then
    error_exit "CA '$ca_name' não encontrada em $base_path"
    return 1
  fi

  # 2. Busca pelo CSR mais recente (.csr.pem)
  if [[ -d "$csr_dir" ]]; then
    local csr_file=$(ls -t "$csr_dir"/*.csr.pem 2>/dev/null | head -n 1)
  fi

  if [[ -z "$csr_file" || ! -f "$csr_file" ]]; then
    error_exit "Não foi encontrada nenhuma CSR em $csr_dir"
    return 1
  fi

  # 3. Define a política de validação
  if [[ "$validation" == "DV"  ]]; then 
	  policy="policy_dv"
  elif [[ "$validation" == "OV"  ]]; then 
	  policy="policy_ov"
  else 
	  policy="policy_ev"
	fi

  # 3. Preparação do diretório de saída
  if [[ ! -d "$new_cert_dir" ]]; then
    echo "[+] Criando diretório de saída: $new_cert_dir"
    mkdir -p "$new_cert_dir"
  fi

  # 4. Assinatura do Certificado
  echo "[+] Usando CSR mais recente: $(basename "$csr_file")"
  echo "[+] Assinando com a CA '$ca_name'..."
  
  openssl ca -days 365 \
    -in "$csr_file" \
    -out "$new_cert_file" \
	  -config "$ca_conf_file" \
		-policy "$policy" \
		-rand_serial

  # 5. Verificação de Sucesso
  if [[ $? -eq 0 ]]; then
    echo "[V] Sucesso! Certificado gerado em: $new_cert_dir"
  else
    error_exit "Não foi possível concluir a  assinatura do certificado."
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
      CSR_NAME="$OPTARG"
      ;;
		v)
		  VALIDATION="$OPTARG"
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
newcert "$CA_NAME" "$CSR_NAME" "$VALIDATION"
