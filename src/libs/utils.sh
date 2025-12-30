#!/bin/bash
# --- Funções de Utilitário ---


# Função para exibir mensagens de erro e sair

error_exit() {
    echo -e "\n[ERRO] $1" >&2 # Redireciona para stderr
    exit 1
}

formatstring() {
    local input="$1"

    # 1. Remove espaços no início e no final (trim)
    # 2. Converte para minúscula
    # 3. Remove acentos usando iconv (converte para ASCII puro)
    # 4. Remove todos os espaços internos

    echo "$input" | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
        tr '[:upper:]' '[:lower:]' | \
        iconv -f UTF-8 -t ASCII//TRANSLIT | \
        tr -d '[:space:]'
        #sed 's/[^a-z0-9]//g'
}

x509_ts_to_date() {
    local ts="$1"

    # valida formato básico
    if [[ ! "$ts" =~ ^[0-9]{12}Z$ ]]; then
        echo "Erro: formato inválido. Use YYMMDDhhmmssZ" >&2
        return 1
    fi

    local year="20${ts:0:2}"
    local month="${ts:2:2}"
    local day="${ts:4:2}"
    local hour="${ts:6:2}"
    local min="${ts:8:2}"
    local sec="${ts:10:2}"

    date -u -d "$year-$month-$day $hour:$min:$sec" "+%d/%m/%Y %H:%M:%S UTC"
}

