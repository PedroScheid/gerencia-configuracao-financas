#!/bin/bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════
# Promove build de Homologação → Produção
# Uso: ./scripts/promote-prod.sh
# ══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

DOCKER_IMAGE="financas-app"
PROD_CONTAINER="financas-producao"
PROD_PORT="3000"
NETWORK="financas-network"
VOLUME="financas-producao-data"

echo "═══════════════════════════════════════════════════"
echo "  Promovendo para PRODUÇÃO"
echo "═══════════════════════════════════════════════════"

# Verifica se a imagem de homologação existe
if ! docker image inspect ${DOCKER_IMAGE}:homolog &>/dev/null; then
    echo "ERRO: Imagem ${DOCKER_IMAGE}:homolog não encontrada."
    echo "Execute a promoção para homologação primeiro."
    exit 1
fi

# Tag para produção
echo "[1/4] Tagueando imagem para produção..."
docker tag ${DOCKER_IMAGE}:homolog ${DOCKER_IMAGE}:production

# Cria network se não existir
docker network create ${NETWORK} 2>/dev/null || true

# Cria volume se não existir
docker volume create ${VOLUME} 2>/dev/null || true

# Para e remove container antigo
echo "[2/4] Removendo container anterior..."
docker stop ${PROD_CONTAINER} 2>/dev/null || true
docker rm ${PROD_CONTAINER} 2>/dev/null || true

# Libera porta 3000 se algo antigo estiver usando (PM2, node, etc)
BLOCKING_PID=$(sudo lsof -ti:${PROD_PORT} 2>/dev/null || true)
if [ -n "$BLOCKING_PID" ]; then
    echo "      Liberando porta ${PROD_PORT} (PID: $BLOCKING_PID)..."
    sudo kill -9 $BLOCKING_PID 2>/dev/null || true
    sleep 2
fi

# Sobe novo container
echo "[3/4] Criando container de produção..."
docker run -d \
    --name ${PROD_CONTAINER} \
    --network ${NETWORK} \
    -p ${PROD_PORT}:3000 \
    -v ${VOLUME}:/data \
    -e NODE_ENV=production \
    -e PORT=3000 \
    --restart unless-stopped \
    ${DOCKER_IMAGE}:production

# Aguarda health check
echo "[4/4] Aguardando aplicação iniciar..."
sleep 5

if docker ps --filter "name=${PROD_CONTAINER}" --filter "status=running" | grep -q ${PROD_CONTAINER}; then
    echo ""
    echo "✓ Produção atualizada com sucesso!"
    echo "  URL: http://localhost:${PROD_PORT}"
    echo "═══════════════════════════════════════════════════"
else
    echo "ERRO: Container não iniciou corretamente."
    docker logs ${PROD_CONTAINER}
    exit 1
fi
