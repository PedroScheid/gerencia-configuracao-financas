#!/bin/bash
set -eo pipefail

# ══════════════════════════════════════════════════════════════
# Reset para Apresentacao (lado VM) — LIMPEZA TOTAL
# Deixa a VM "como nova": remove TODOS os containers, imagens da
# app, volumes e a rede. O setup-vm.sh reergue tudo depois.
#
# Objetivo: mostrar ao professor que nao existe nada rodando
# (docker ps vazio) antes de subir o ambiente pelo setup.
#
# NOTA: a imagem financas-jenkins:latest e PRESERVADA (cache),
# para o setup nao precisar rebuildar (~9 min). Use --full para
# remover tambem a imagem do Jenkins.
# ══════════════════════════════════════════════════════════════

FULL=0
[ "${1:-}" = "--full" ] && FULL=1

echo ""
echo "==================================================="
echo "  RESET PARA APRESENTACAO (limpeza total da VM)"
echo "==================================================="
echo ""

# Para e remove TODOS os containers
echo "[1/4] Parando e removendo todos os containers..."
CIDS=$(docker ps -aq)
if [ -n "$CIDS" ]; then
    docker stop $CIDS 2>/dev/null || true
    docker rm -f $CIDS 2>/dev/null || true
    echo "      Containers removidos."
else
    echo "      Nenhum container."
fi

# Remove imagens da aplicacao (e Jenkins se --full)
echo "[2/4] Removendo imagens da aplicacao..."
docker images --format '{{.Repository}}:{{.Tag}}' | grep '^financas-app:' | xargs -r docker rmi -f 2>/dev/null || true
if [ "$FULL" = "1" ]; then
    echo "      (--full) Removendo tambem a imagem do Jenkins..."
    docker rmi -f financas-jenkins:latest 2>/dev/null || true
else
    echo "      Imagem financas-jenkins:latest PRESERVADA (cache p/ setup rapido)."
fi

# Remove volumes
echo "[3/4] Removendo volumes..."
for VOL in jenkins-data financas-integracao-data financas-homologacao-data financas-producao-data; do
    docker volume rm "$VOL" 2>/dev/null && echo "      Removido: $VOL" || true
done

# Remove a rede
echo "[4/4] Removendo a rede financas-network..."
docker network rm financas-network 2>/dev/null && echo "      Rede removida." || echo "      Rede ja nao existe."

echo ""
echo "==================================================="
echo "  RESET CONCLUIDO! VM limpa."
echo ""
echo "  Estado atual do Docker (deve estar vazio):"
docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || docker ps -a
echo ""
echo "  Proximo passo: rodar o setup-vm para subir tudo."
echo "==================================================="
echo ""
