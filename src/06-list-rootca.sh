#!/bin/bash

# Configurações de segurança do shell
set -euo pipefail

# --- Variáveis Globais ---
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SRC_DIR")"
UTILS="$SRC_DIR/libs/utils.sh"
[[ -f "$UTILS" ]] && source "$UTILS" || {
  echo "[ERRO] Função de utilitários não encontrados em $UTILS." >&2
  exit 1
}

listrootca() {
  local base_path="$PARENT_DIR/ca"
	[[ ! -d "$base_path" ]] && error_exit "Estrutura de CA inexistente em $base_path"

	echo ""
  echo "==============================================================="
  echo "           LISTA DE AUTORIDADES CERTIFICADORAS                 "
	echo "==============================================================="

	for item in "$base_path"/*/; do
    if [[ -d "$item" ]]; then
      # 1. Remove a barra final para o basename funcionar corretamente
      local path_no_slash="${item%/}"
      
      # 2. Extrai o nome da pasta e converte para maiúsculas (usando bash expansion)
      local ca_name=$(basename "$path_no_slash")
      local ca_upper="${ca_name^^}"
      
      # 3. Exibe formatado: NOME | CAMINHO
      # O caractere \t adiciona um tab para alinhar, ou use espaços fixos
			printf "%-8s | %s\n" "$ca_upper" "$path_no_slash"
    fi
  done

	echo -e "\n===============================================================\n"

}

# Execução principal
listrootca
