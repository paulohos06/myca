#!/bin/bash


# --- Funções de Utilitário ---
UTILS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/00-util.sh"

if [[ -f "$UTILS" ]]; then
  source "$UTILS"
else
  echo "Erro: Arquivo de utilidades não encontrado em $UTILS." >&2
  exit 1
fi

# --- Variáveis Globais ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"
PKI_SUBDIRS=(certs conf crl csr newcerts private)
MODULE_NAME="" # preenchida pelo getops

# --- Função Principal: Criação da AC Raiz ---
newrootca() {
  local module_name="$1"
	local CA_BASE_DIR="$PARENT_DIR/ca"

	if [[ "$PWD" == "$PKI_BASE_DIR" ]]; then
	  echo "[!] Execute o script na raiz do projeto."
	  return 0
	fi

  # Valida se o nome foi fornecido
  validate_module_name "$module_name" || return 1
    
  # Verifica se o diretório já existe
  if [[ -d "$module_name" ]]; then
    echo "[!] Já existe uma AC raiz com esse nome: '$module_name'. Ação ignorada."
    return 0
  fi

  # Criando a nova AC Raiz
  echo "[+] Criando AC Raiz: '$module_name'..."

  ## etapa 1 & 2. Cria o diretório principal e a estrutura de subdiretórios
  for dir in "" "${PKI_SUBDIRS[@]}"; do
    mkdir -p "$CA_BASE_DIR/$module_name/$dir" || error_exit "Falha ao criar subdiretório '$dir' em '$module_name'."
  done

  ## etapa 3. Configura as permissões e arquivos iniciais
  echo "[+] Inicializando arquivos de índice e permissões..."
  chmod 700 "$CA_BASE_DIR/$module_name/private"
  touch "$CA_BASE_DIR/$module_name/index.txt"
  #echo 1000 > "$CA_BASE_DIR/$module_name/serial"
  #echo 1000 > "$CA_BASE_DIR/$module_name/crlnumber"

  ## etapa 4. Copia os arquivos de configuração
  echo "[+] Copiando arquivos de configuração..."
  if [[ -d "$CA_BASE_DIR/$module_name"/conf ]]; then
    cp -r "$SRC_DIR/conf/ca.cnf" "$CA_BASE_DIR/$module_name/conf/$module_name.cnf" || error_exit "Falha ao copiar o arquivo de configuração da CA"
    cp -r "$SRC_DIR/conf/profiles" "$CA_BASE_DIR/$module_name/conf/" || error_exit "Falha ao copiar arquivos de configuração."
    sed -i \
      -e "s|/pathdir/|$CA_BASE_DIR/$module_name|" \
      -e "s|ca.key.pem|$module_name.key.pem|" \
      -e "s|ca.cert.pem|$module_name.cert.pem|" \
		  "$CA_BASE_DIR/$module_name/conf/$module_name.cnf"
  else
    error_exit "Diretório de configuração '$module_name/conf' não encontrado após a criação."
  fi

  ## etapa 5. Cria o par de chaves da nova root ca
  echo "[+] Gerando a chave privada de 4096 bits para a AC raiz '$module_name'..."
  OPENSSL_KEY_PATH="$CA_BASE_DIR/$module_name/private/$module_name.key.pem"
  openssl genrsa -aes256 -out "$OPENSSL_KEY_PATH" 4096 || error_exit "Falha ao gerar a chave privada da AC raiz '$module_name'."

  ## etapa 6. Cria o certificado autoassinado (Self-Signed)
  if [[ -f "$OPENSSL_KEY_PATH" ]]; then
    echo "[+] Gerando o certificado autoassinado (3650 dias)..."
    openssl req \
      -config "$CA_BASE_DIR/$module_name/conf/$module_name.cnf" -extensions req_ext \
      -key "$OPENSSL_KEY_PATH" \
      -new -x509 -days 3650 -sha512 \
      -out "$CA_BASE_DIR/$module_name/certs/$module_name.cert.pem" || error_exit "Falha ao gerar o certificado autoassinado."
  else
    error_exit "Chave privada não encontrada em '$OPENSSL_KEY_PATH'. Não foi possível criar o certificado."
  fi

  # Finalizada a criação da nova root ca
  echo -e "\n[+] AC Raiz '$module_name' criada e inicializada com sucesso."
  echo "  - Chave: $CA_BASE_DIR/$module_name/private/$module_name.key.pem"
  echo "  - Cert:  $CA_BASE_DIR/$module_name/certs/$module_name.cert.pem"
}

# Usa getopts para analisar as opções da linha de comando
while getopts "n:h" opt; do
  case $opt in
    n)
      # Captura o valor do argumento -name
      MODULE_NAME="$OPTARG"
      ;;
    h)
      show_help
      exit 0
      ;;
    \?)
      echo "Opção inválida: -$OPTARG" >&2
      show_help
      exit 1
      ;;
  esac
done
newrootca "$MODULE_NAME"
