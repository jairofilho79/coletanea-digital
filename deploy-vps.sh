#!/bin/bash
# =============================================================================
# deploy-vps.sh - Deploy do coletanea-digital para a VPS
# =============================================================================
# Uso:
#   ./deploy-vps.sh              # Deploy completo (sync + build + up)
#   ./deploy-vps.sh sync         # Apenas sincronizar arquivos
#   ./deploy-vps.sh build        # Apenas rebuild dos containers
#   ./deploy-vps.sh up           # Apenas subir containers
#   ./deploy-vps.sh down         # Parar containers
#   ./deploy-vps.sh logs         # Ver logs
#   ./deploy-vps.sh status       # Ver status dos containers
#   ./deploy-vps.sh health       # Verificar saúde da API
#   ./deploy-vps.sh setup        # Setup inicial (redes, diretórios, nginx)
#
# Variáveis de ambiente opcionais:
#   VPS_IP          - IP da VPS (default: 129.121.44.196)
#   VPS_USER        - Usuário SSH (default: root)
#   VPS_DEPLOY_DIR  - Diretório no VPS (default: /opt/coletanea-digital)
#   SSH_KEY         - Caminho para chave SSH (default: detecta automaticamente)
# =============================================================================

set -euo pipefail

# ─── Configuração ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

VPS_IP="${VPS_IP:-129.121.44.196}"
VPS_USER="${VPS_USER:-root}"
VPS_DEPLOY_DIR="${VPS_DEPLOY_DIR:-/opt/coletanea-digital}"
SSH_KEY="${SSH_KEY:-}"

# Portas (devem bater com docker-compose.prod.yml)
API_PORT=8001
DB_PORT=5433

# Rede Docker compartilhada com coldigom
DOCKER_NETWORK="coldigom-coletanea-prod-network"

# ─── Cores e formatação ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERRO]${NC} $*"; }

# ─── Funções auxiliares ────────────────────────────────────────────────────

# Monta o comando SSH base
ssh_cmd() {
    local ssh_opts="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"
    if [ -n "$SSH_KEY" ]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi
    ssh $ssh_opts "${VPS_USER}@${VPS_IP}" "$@"
}

# Monta o comando rsync base
rsync_cmd() {
    local rsync_opts="-avz --delete --progress"
    if [ -n "$SSH_KEY" ]; then
        rsync_opts="$rsync_opts -e \"ssh -i $SSH_KEY -o StrictHostKeyChecking=accept-new\""
    else
        rsync_opts="$rsync_opts -e \"ssh -o StrictHostKeyChecking=accept-new\""
    fi
    eval rsync $rsync_opts "$@"
}

# Verifica pré-requisitos locais
check_local_prereqs() {
    log_info "Verificando pré-requisitos locais..."

    if ! command -v ssh &>/dev/null; then
        log_error "ssh não encontrado. Instale o OpenSSH."
        exit 1
    fi

    if ! command -v rsync &>/dev/null; then
        log_error "rsync não encontrado. Instale com: brew install rsync"
        exit 1
    fi

    # Verificar arquivos necessários
    if [ ! -f "$PROJECT_DIR/docker-compose.prod.yml" ]; then
        log_error "docker-compose.prod.yml não encontrado em $PROJECT_DIR"
        exit 1
    fi

    if [ ! -f "$PROJECT_DIR/backend/.env.prod" ]; then
        log_error "backend/.env.prod não encontrado!"
        log_warn "Crie baseado em backend/.env.example"
        exit 1
    fi

    # Alertar sobre senhas padrão
    if grep -q "CHANGE_THIS" "$PROJECT_DIR/backend/.env.prod" 2>/dev/null; then
        log_warn "backend/.env.prod contém senhas padrão (CHANGE_THIS)!"
        log_warn "Atualize as senhas antes de deployar em produção."
        read -p "Continuar mesmo assim? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi

    log_success "Pré-requisitos locais OK"
}

# Verifica conexão SSH com a VPS
check_vps_connection() {
    log_info "Testando conexão SSH com ${VPS_USER}@${VPS_IP}..."
    if ! ssh_cmd "echo 'OK'" &>/dev/null; then
        log_error "Não foi possível conectar à VPS ${VPS_IP}"
        log_warn "Verifique:"
        log_warn "  - IP correto: VPS_IP=$VPS_IP"
        log_warn "  - Usuário correto: VPS_USER=$VPS_USER"
        log_warn "  - Chave SSH configurada: SSH_KEY=$SSH_KEY"
        exit 1
    fi
    log_success "Conexão SSH OK"
}

# Verifica pré-requisitos na VPS
check_vps_prereqs() {
    log_info "Verificando pré-requisitos na VPS..."

    local missing=""
    if ! ssh_cmd "command -v docker" &>/dev/null; then
        missing="$missing docker"
    fi
    if ! ssh_cmd "command -v docker compose" &>/dev/null && ! ssh_cmd "command -v docker-compose" &>/dev/null; then
        missing="$missing docker-compose"
    fi

    if [ -n "$missing" ]; then
        log_error "Ferramentas ausentes na VPS:$missing"
        log_warn "Instale Docker e Docker Compose na VPS."
        exit 1
    fi

    log_success "Pré-requisitos na VPS OK"
}

# Detecta se a VPS usa `docker compose` (plugin) ou `docker-compose` (standalone)
detect_compose_cmd() {
    if ssh_cmd "docker compose version" &>/dev/null; then
        echo "docker compose"
    elif ssh_cmd "docker-compose version" &>/dev/null; then
        echo "docker-compose"
    else
        log_error "Nenhum docker-compose encontrado na VPS!"
        exit 1
    fi
}

# ─── Comandos principais ──────────────────────────────────────────────────

# Setup inicial na VPS (executar apenas uma vez)
cmd_setup() {
    log_info "=== Setup inicial na VPS ==="

    check_local_prereqs
    check_vps_connection
    check_vps_prereqs

    log_info "Criando diretório de deploy: $VPS_DEPLOY_DIR"
    ssh_cmd "mkdir -p $VPS_DEPLOY_DIR"

    log_info "Criando rede Docker: $DOCKER_NETWORK"
    ssh_cmd "docker network inspect $DOCKER_NETWORK >/dev/null 2>&1 || docker network create $DOCKER_NETWORK"
    log_success "Rede $DOCKER_NETWORK criada/verificada"

    # Copiar nginx config
    log_info "Copiando configuração do NGINX..."
    rsync_cmd "$PROJECT_DIR/nginx-deploy.conf" "${VPS_USER}@${VPS_IP}:/tmp/coletanea-nginx.conf"

    # Verificar se nginx está instalado e configurar
    if ssh_cmd "command -v nginx" &>/dev/null; then
        ssh_cmd "cp /tmp/coletanea-nginx.conf /etc/nginx/sites-available/coletanea-digital.conf"
        ssh_cmd "ln -sf /etc/nginx/sites-available/coletanea-digital.conf /etc/nginx/sites-enabled/"
        if ssh_cmd "nginx -t" &>/dev/null; then
            ssh_cmd "systemctl reload nginx 2>/dev/null || nginx -s reload 2>/dev/null || true"
            log_success "NGINX configurado e recarregado"
        else
            log_warn "Configuração NGINX inválida - verifique manualmente"
        fi
    else
        log_warn "NGINX não encontrado na VPS. Instale e configure manualmente."
        log_warn "Config disponível em: /tmp/coletanea-nginx.conf"
    fi

    log_success "=== Setup inicial concluído ==="
    echo ""
    log_info "Próximo passo: ./deploy-vps.sh"
}

# Sincronizar arquivos para a VPS
cmd_sync() {
    log_info "=== Sincronizando arquivos para VPS ==="

    # Lista de exclusões (não enviar para VPS)
    local excludes=(
        "--exclude=.git"
        "--exclude=.gitignore"
        "--exclude=frontend/"
        "--exclude=node_modules/"
        "--exclude=__pycache__/"
        "--exclude=*.pyc"
        "--exclude=.pytest_cache/"
        "--exclude=.mypy_cache/"
        "--exclude=.venv/"
        "--exclude=venv/"
        "--exclude=.env"
        "--exclude=.env.dev"
        "--exclude=backend/.env"
        "--exclude=backend/.env.dev"
        "--exclude=backend/.env.example"
        "--exclude=postgres_data*"
        "--exclude=dev-local-*.sh"
        "--exclude=dev-vps-*.sh"
        "--exclude=*.log"
        "--exclude=.DS_Store"
        "--exclude=.claude/"
    )

    # Arquivos necessários no VPS:
    #   - docker-compose.prod.yml
    #   - backend/ (Dockerfile, código, requirements.txt, alembic/, scripts/, .env.prod)
    #   - nginx-deploy.conf
    #   - setup-docker-networks.sh

    rsync_cmd \
        "${excludes[@]}" \
        "$PROJECT_DIR/docker-compose.prod.yml" \
        "${VPS_USER}@${VPS_IP}:${VPS_DEPLOY_DIR}/"

    rsync_cmd \
        "${excludes[@]}" \
        "$PROJECT_DIR/backend/" \
        "${VPS_USER}@${VPS_IP}:${VPS_DEPLOY_DIR}/backend/"

    rsync_cmd \
        "$PROJECT_DIR/nginx-deploy.conf" \
        "${VPS_USER}@${VPS_IP}:${VPS_DEPLOY_DIR}/"

    rsync_cmd \
        "$PROJECT_DIR/setup-docker-networks.sh" \
        "${VPS_USER}@${VPS_IP}:${VPS_DEPLOY_DIR}/"

    log_success "Arquivos sincronizados"
}

# Build dos containers na VPS
cmd_build() {
    log_info "=== Build dos containers na VPS ==="

    local compose_cmd
    compose_cmd=$(detect_compose_cmd)

    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml build --no-cache"

    log_success "Build concluído"
}

# Subir containers na VPS
cmd_up() {
    log_info "=== Subindo containers na VPS ==="

    local compose_cmd
    compose_cmd=$(detect_compose_cmd)

    # Garantir que a rede existe
    ssh_cmd "docker network inspect $DOCKER_NETWORK >/dev/null 2>&1 || docker network create $DOCKER_NETWORK"

    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml up -d"

    log_info "Aguardando containers ficarem saudáveis..."
    sleep 5

    # Verificar status
    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml ps"

    log_success "Containers rodando"
}

# Parar containers na VPS
cmd_down() {
    log_info "=== Parando containers na VPS ==="

    local compose_cmd
    compose_cmd=$(detect_compose_cmd)

    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml down"

    log_success "Containers parados"
}

# Ver logs dos containers
cmd_logs() {
    log_info "=== Logs dos containers (Ctrl+C para sair) ==="

    local compose_cmd
    compose_cmd=$(detect_compose_cmd)

    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml logs -f --tail=100"
}

# Status dos containers
cmd_status() {
    log_info "=== Status dos containers na VPS ==="

    local compose_cmd
    compose_cmd=$(detect_compose_cmd)

    echo ""
    log_info "Docker Compose:"
    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml ps"

    echo ""
    log_info "Redes Docker:"
    ssh_cmd "docker network ls | grep -E 'coldigom|coletanea' || echo '  (nenhuma rede encontrada)'"

    echo ""
    log_info "Volumes Docker:"
    ssh_cmd "docker volume ls | grep -E 'coletanea' || echo '  (nenhum volume encontrado)'"
}

# Verificar saúde da API
cmd_health() {
    log_info "=== Verificando saúde da API ==="

    echo ""
    log_info "Health check (coletanea-digital API - porta $API_PORT):"
    local health_response
    if health_response=$(ssh_cmd "curl -s -o /dev/null -w '%{http_code}' http://localhost:$API_PORT/health 2>/dev/null"); then
        if [ "$health_response" = "200" ]; then
            log_success "API coletanea-digital: HEALTHY (HTTP $health_response)"
            ssh_cmd "curl -s http://localhost:$API_PORT/health 2>/dev/null" | python3 -m json.tool 2>/dev/null || true
        else
            log_error "API coletanea-digital: UNHEALTHY (HTTP $health_response)"
        fi
    else
        log_error "API coletanea-digital: NÃO ACESSÍVEL na porta $API_PORT"
    fi

    echo ""
    log_info "Health check externo (http://$VPS_IP:$API_PORT/health):"
    if command -v curl &>/dev/null; then
        local ext_response
        if ext_response=$(curl -s -o /dev/null -w '%{http_code}' "http://$VPS_IP:$API_PORT/health" 2>/dev/null); then
            if [ "$ext_response" = "200" ]; then
                log_success "API externa: ACESSÍVEL (HTTP $ext_response)"
            else
                log_warn "API externa: HTTP $ext_response"
            fi
        else
            log_warn "API externa: NÃO ACESSÍVEL (firewall? porta $API_PORT bloqueada?)"
        fi
    fi

    echo ""
    log_info "Verificando coldigom API (porta 8000):"
    if health_response=$(ssh_cmd "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/api/v1/ 2>/dev/null"); then
        if [ "$health_response" = "200" ]; then
            log_success "API coldigom: ACESSÍVEL (HTTP $health_response)"
        else
            log_warn "API coldigom: HTTP $health_response"
        fi
    else
        log_warn "API coldigom: NÃO ACESSÍVEL na porta 8000"
        log_warn "Se o coldigom não estiver rodando, as tags não serão carregadas!"
    fi

    echo ""
    log_info "Verificando endpoint de tags do coldigom:"
    if ssh_cmd "curl -s http://localhost:8000/api/v1/praise-tags/ 2>/dev/null | head -c 500"; then
        echo ""
    else
        log_warn "Não foi possível acessar /api/v1/praise-tags/"
    fi

    echo ""
    log_info "Verificando endpoint de traduções do coldigom:"
    if ssh_cmd "curl -s 'http://localhost:8000/api/v1/translations/praise-tags?language_code=pt' 2>/dev/null | head -c 500"; then
        echo ""
    else
        log_warn "Não foi possível acessar /api/v1/translations/praise-tags"
        log_warn "Sem traduções, as tags aparecerão com nomes originais (possivelmente UUIDs)"
    fi
}

# Deploy completo (sync + build + up)
cmd_deploy() {
    log_info "========================================="
    log_info "  Deploy: coletanea-digital -> VPS"
    log_info "  VPS: ${VPS_USER}@${VPS_IP}"
    log_info "  Dir: ${VPS_DEPLOY_DIR}"
    log_info "========================================="
    echo ""

    check_local_prereqs
    check_vps_connection
    check_vps_prereqs

    cmd_sync
    echo ""

    # Parar containers existentes
    log_info "Parando containers existentes (se houver)..."
    local compose_cmd
    compose_cmd=$(detect_compose_cmd)
    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml down 2>/dev/null || true"
    echo ""

    cmd_build
    echo ""

    cmd_up
    echo ""

    # Aguarda mais um pouco para o health check
    log_info "Aguardando API ficar pronta..."
    sleep 10

    cmd_health

    echo ""
    log_success "========================================="
    log_success "  Deploy concluído!"
    log_success "========================================="
    echo ""
    log_info "Endpoints:"
    log_info "  - API: http://${VPS_IP}:${API_PORT}"
    log_info "  - Health: http://${VPS_IP}:${API_PORT}/health"
    log_info "  - Docs: http://${VPS_IP}:${API_PORT}/docs"
    echo ""
    log_info "Comandos úteis:"
    log_info "  ./deploy-vps.sh logs     - Ver logs"
    log_info "  ./deploy-vps.sh status   - Ver status"
    log_info "  ./deploy-vps.sh health   - Verificar saúde"
    log_info "  ./deploy-vps.sh down     - Parar containers"
}

# ─── Restart (down + up sem rebuild) ──────────────────────────────────────

cmd_restart() {
    log_info "=== Reiniciando containers na VPS ==="

    local compose_cmd
    compose_cmd=$(detect_compose_cmd)

    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml down"
    sleep 2
    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml up -d"

    log_info "Aguardando containers..."
    sleep 5
    ssh_cmd "cd $VPS_DEPLOY_DIR && $compose_cmd -f docker-compose.prod.yml ps"

    log_success "Containers reiniciados"
}

# ─── Main ──────────────────────────────────────────────────────────────────

ACTION="${1:-deploy}"

case "$ACTION" in
    setup)    cmd_setup ;;
    sync)     check_vps_connection && cmd_sync ;;
    build)    check_vps_connection && cmd_build ;;
    up)       check_vps_connection && cmd_up ;;
    down)     check_vps_connection && cmd_down ;;
    restart)  check_vps_connection && cmd_restart ;;
    logs)     check_vps_connection && cmd_logs ;;
    status)   check_vps_connection && cmd_status ;;
    health)   check_vps_connection && cmd_health ;;
    deploy)   cmd_deploy ;;
    *)
        echo "Uso: $0 {deploy|setup|sync|build|up|down|restart|logs|status|health}"
        echo ""
        echo "Comandos:"
        echo "  deploy   - Deploy completo (sync + build + up) [padrão]"
        echo "  setup    - Setup inicial (redes, nginx, diretórios)"
        echo "  sync     - Sincronizar arquivos para VPS"
        echo "  build    - Rebuild dos containers"
        echo "  up       - Subir containers"
        echo "  down     - Parar containers"
        echo "  restart  - Reiniciar containers (down + up)"
        echo "  logs     - Ver logs dos containers"
        echo "  status   - Status dos containers"
        echo "  health   - Verificar saúde das APIs"
        echo ""
        echo "Variáveis de ambiente:"
        echo "  VPS_IP=$VPS_IP"
        echo "  VPS_USER=$VPS_USER"
        echo "  VPS_DEPLOY_DIR=$VPS_DEPLOY_DIR"
        echo "  SSH_KEY=${SSH_KEY:-<auto>}"
        exit 1
        ;;
esac
