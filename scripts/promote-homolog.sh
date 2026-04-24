#!/bin/bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════
# Promove build de Integração → Homologação
# Uso: ./scripts/promote-homolog.sh
# ══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

DOCKER_IMAGE="financas-app"
HOMOLOG_CONTAINER="financas-homologacao"
HOMOLOG_PORT="3002"
NETWORK="financas-network"
VOLUME="financas-homologacao-data"

echo "═══════════════════════════════════════════════════"
echo "  Promovendo para HOMOLOGAÇÃO"
echo "═══════════════════════════════════════════════════"

# Verifica se a imagem latest existe (build do Jenkins)
if ! docker image inspect ${DOCKER_IMAGE}:latest &>/dev/null; then
    echo "ERRO: Imagem ${DOCKER_IMAGE}:latest não encontrada."
    echo "Execute o pipeline de integração primeiro."
    exit 1
fi

# Tag para homologação
echo "[1/4] Tagueando imagem para homologação..."
docker tag ${DOCKER_IMAGE}:latest ${DOCKER_IMAGE}:homolog

# Cria network se não existir
docker network create ${NETWORK} 2>/dev/null || true

# Cria volume se não existir
docker volume create ${VOLUME} 2>/dev/null || true

# Para e remove container antigo
echo "[2/4] Removendo container anterior..."
docker stop ${HOMOLOG_CONTAINER} 2>/dev/null || true
docker rm ${HOMOLOG_CONTAINER} 2>/dev/null || true

# Sobe novo container
echo "[3/4] Criando container de homologação..."
docker run -d \
    --name ${HOMOLOG_CONTAINER} \
    --network ${NETWORK} \
    -p ${HOMOLOG_PORT}:3000 \
    -v ${VOLUME}:/data \
    -e NODE_ENV=homologation \
    -e PORT=3000 \
    --restart unless-stopped \
    ${DOCKER_IMAGE}:homolog

# Aguarda health check
echo "[4/4] Aguardando aplicação iniciar..."
sleep 5

if docker ps --filter "name=${HOMOLOG_CONTAINER}" --filter "status=running" | grep -q ${HOMOLOG_CONTAINER}; then
    echo ""
    echo "✓ Homologação atualizada com sucesso!"
    echo "  URL: http://localhost:${HOMOLOG_PORT}"
    echo "═══════════════════════════════════════════════════"
else
    echo "ERRO: Container não iniciou corretamente."
    docker logs ${HOMOLOG_CONTAINER}
    exit 1
fi
