#!/usr/bin/env bats

setup() {
  # Carrega as bibliotecas
  load 'libs/bats-support/load'
  load 'libs/bats-assert/load'
  load 'libs/bats-file/load'

  # Mock do arquivo de utilitários se necessário, ou apenas source
	PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$PROJECT_ROOT/src/01-create-rootca.sh"

	TEST_TEMP_DIR="$(mktemp -d "${BATS_TMPDIR}/bats-test.XXXXXX")"
	export CA_BASE_DIR="$TEST_TEMP_DIR"
}

teardown() {
  if [ "$BATS_TEST_COMPLETED" -eq 1 ]; then
    rm -rf "$TEST_TEMP_DIR"
  else
    echo "Teste falhou. Verifique os arquivos em: $TEST_TEMP_DIR" >&3
  fi
}

# --- Casos de Teste ---
@test "Execução do script: deve falhar se não informar o nome da nova CA" {
	run bash "$SCRIPT"
	
	assert_failure
  assert_equal "$status" 1
}

@test "Validação da nova CA: deve falhar se a CA já existir" {
	mkdir -p "$CA_BASE_DIR/duplicateca"
	run timeout 2s bash "$SCRIPT" -n "duplicateca"

  assert_failure
  assert_output --partial "A CA informada já existe."
}

<<comment
@test "Criação completa: deve gerar estrutura e arquivos com sucesso" {
  export CA_PASS="test_password"
  run bash "$SCRIPT" -n "root_test"

  assert_success
  assert_exists "$CA_BASE_DIR/root_test/private/root_test.key.pem"
  assert_exists "$CA_BASE_DIR/root_test/certs/root_test.cert.pem"
  assert_exists "$CA_BASE_DIR/root_test/index.txt"
  assert_file_contains "$CA_BASE_DIR/root_test/conf/root_test.cnf" "root_test.key.pem"
}
comment
