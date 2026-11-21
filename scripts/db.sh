#!/usr/bin/env bash
# =====================================================================
# Automação do ambiente Docker (MySQL 8.2) do Sistema de Captação de
# Projetos Universitários.
#
# Uso: ./scripts/db.sh <comando> [argumentos]
# Ajuda: ./scripts/db.sh help
# Tutorial: docs/TUTORIAL_DOCKER.md
# =====================================================================
set -euo pipefail

# Sempre executar a partir da raiz do repositório.
cd "$(dirname "$0")/.."

readonly SERVICO="mysql"
readonly BANCO="sistema_captacao_projetos"
readonly SENHA_ROOT="root"          # igual ao docker-compose.yml
readonly DDL="sql/ddl.sql"
readonly TESTE="sql/teste_ddl.sql"

# ---------- saída colorida (desligada fora de terminal) ----------
if [[ -t 1 ]]; then
    COR_AZUL=$'\033[1;34m'; COR_VERDE=$'\033[1;32m'
    COR_AMARELO=$'\033[1;33m'; COR_VERMELHO=$'\033[1;31m'; COR_FIM=$'\033[0m'
else
    COR_AZUL=""; COR_VERDE=""; COR_AMARELO=""; COR_VERMELHO=""; COR_FIM=""
fi

info()  { echo "${COR_AZUL}==>${COR_FIM} $*"; }
ok()    { echo "${COR_VERDE}OK:${COR_FIM} $*"; }
aviso() { echo "${COR_AMARELO}AVISO:${COR_FIM} $*"; }
erro()  { echo "${COR_VERMELHO}ERRO:${COR_FIM} $*" >&2; exit 1; }

# ---------- verificações ----------
verificar_docker() {
    command -v docker >/dev/null 2>&1 \
        || erro "docker não encontrado. Instale o Docker Engine."
    docker compose version >/dev/null 2>&1 \
        || erro "plugin 'docker compose' não encontrado. Instale o Docker Compose v2."
    docker info >/dev/null 2>&1 \
        || erro "o daemon do Docker não respondeu. Ele está rodando? Seu usuário está no grupo 'docker'?"
}

verificar_rodando() {
    local estado
    estado="$(docker compose ps --format '{{.Health}}' "$SERVICO" 2>/dev/null || true)"
    [[ "$estado" == "healthy" ]] \
        || erro "o container não está rodando (ou ainda não está pronto). Use: ./scripts/db.sh up"
}

banco_existe() {
    [[ -n "$(mysql_exec -N -e "SHOW DATABASES LIKE '$BANCO';")" ]]
}

# Cliente mysql de dentro do container; o SQL chega pela entrada padrão.
mysql_exec() {
    docker compose exec -T -e MYSQL_PWD="$SENHA_ROOT" "$SERVICO" mysql -uroot "$@"
}

# ---------- comandos ----------
cmd_up() {
    info "Subindo o MySQL 8.2 (a primeira vez baixa a imagem)..."
    docker compose up -d --wait
    ok "MySQL pronto."
    echo "    Host: localhost  Porta: 3306  Usuário: root  Senha: $SENHA_ROOT"
    echo "    Próximo passo: ./scripts/db.sh ddl"
}

cmd_down() {
    info "Parando e removendo o container (os dados serão perdidos)..."
    docker compose down
    ok "Ambiente parado."
}

cmd_restart() {
    cmd_down
    cmd_up
}

cmd_ddl() {
    verificar_rodando
    info "Aplicando $DDL (recria o banco $BANCO do zero)..."
    mysql_exec < "$DDL"
    local tabelas triggers
    tabelas="$(mysql_exec -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$BANCO';")"
    triggers="$(mysql_exec -N -e "SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = '$BANCO';")"
    ok "DDL aplicado: $tabelas tabelas (esperado 20), $triggers triggers (esperado 7)."
}

cmd_test() {
    verificar_rodando
    banco_existe || erro "o banco $BANCO não existe. Rode antes: ./scripts/db.sh ddl"
    info "Executando $TESTE..."
    aviso "os erros da PARTE 2 são esperados (cada um está anotado no arquivo)."
    # --force: continua após os erros esperados; a saída de erro é mantida.
    mysql_exec --force --table "$BANCO" < "$TESTE" || true
    ok "Teste concluído. Confira se Esperado = Encontrado na tabela acima."
}

cmd_reset() {
    cmd_ddl
    cmd_test
}

cmd_shell() {
    verificar_rodando
    local alvo=()
    banco_existe && alvo=("$BANCO")
    info "Abrindo o console do MySQL (saia com 'exit')..."
    docker compose exec -e MYSQL_PWD="$SENHA_ROOT" "$SERVICO" mysql -uroot "${alvo[@]}"
}

cmd_sql() {
    local arquivo="${1:-}"
    [[ -n "$arquivo" ]] || erro "informe o arquivo. Ex.: ./scripts/db.sh sql consultas.sql"
    [[ -r "$arquivo" ]] || erro "arquivo não encontrado ou sem permissão de leitura: $arquivo"
    verificar_rodando
    local alvo=()
    banco_existe && alvo=("$BANCO")
    info "Executando $arquivo..."
    mysql_exec --table "${alvo[@]}" < "$arquivo"
}

cmd_logs()   { docker compose logs -f "$SERVICO"; }
cmd_status() { docker compose ps; }

cmd_help() {
    cat <<EOF
Uso: ./scripts/db.sh <comando> [argumentos]

Comandos:
  up            Sobe o MySQL 8.2 e espera ficar pronto
  down          Para e remove o container (os dados são perdidos)
  restart       down + up (o banco volta vazio)
  ddl           Aplica $DDL (recria o banco $BANCO)
  test          Executa $TESTE (inserções válidas e inválidas)
  reset         ddl + test (recria e popula o banco sem reiniciar o container)
  shell         Abre o console mysql no banco $BANCO
  sql <arquivo> Executa um arquivo .sql do host no banco
  logs          Mostra os logs do MySQL (Ctrl+C para sair)
  status        Mostra o estado do container
  help          Mostra esta ajuda

Tutorial completo: docs/TUTORIAL_DOCKER.md
EOF
}

# ---------- entrada ----------
main() {
    local comando="${1:-help}"
    shift || true

    case "$comando" in
        help|-h|--help) cmd_help; return 0 ;;
    esac

    verificar_docker

    case "$comando" in
        up)      cmd_up ;;
        down)    cmd_down ;;
        restart) cmd_restart ;;
        ddl)     cmd_ddl ;;
        test)    cmd_test ;;
        reset)   cmd_reset ;;
        shell)   cmd_shell ;;
        sql)     cmd_sql "$@" ;;
        logs)    cmd_logs ;;
        status)  cmd_status ;;
        *)
            echo "Comando desconhecido: $comando" >&2
            echo >&2
            cmd_help >&2
            exit 1
            ;;
    esac
}

main "$@"
