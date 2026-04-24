#!/bin/bash
set -eo pipefail

# ══════════════════════════════════════════════════════════════
# Reset para Apresentacao
# Remove APENAS containers da aplicacao (integracao, homologacao, producao)
# Mantem Jenkins, Zabbix e toda a infraestrutura intacta
# ══════════════════════════════════════════════════════════════

echo ""
echo "==================================================="
echo "  RESET PARA APRESENTACAO"
echo "  (mantem Jenkins + Zabbix)"
echo "==================================================="
echo ""

# Para e remove containers da aplicacao
echo "[1/4] Removendo containers da aplicacao..."
for CONTAINER in financas-integracao financas-homologacao financas-producao; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        docker stop ${CONTAINER} 2>/dev/null || true
        docker rm ${CONTAINER} 2>/dev/null || true
        echo "      Removido: ${CONTAINER}"
    fi
done

# Remove imagens da aplicacao
echo "[2/4] Removendo imagens da aplicacao..."
for TAG in latest homolog production; do
    if docker image inspect financas-app:${TAG} &>/dev/null; then
        docker rmi financas-app:${TAG} 2>/dev/null || true
        echo "      Removida: financas-app:${TAG}"
    fi
done
# Remove imagens com tag de build number
docker images --format '{{.Repository}}:{{.Tag}}' | grep '^financas-app:' | xargs -r docker rmi 2>/dev/null || true

# Remove volumes da aplicacao (dados SQLite)
echo "[3/4] Removendo volumes da aplicacao..."
for VOL in financas-integracao-data financas-homologacao-data financas-producao-data; do
    if docker volume inspect ${VOL} &>/dev/null; then
        docker volume rm ${VOL} 2>/dev/null || true
        echo "      Removido: ${VOL}"
    fi
done

# Libera portas da aplicacao
echo "[4/4] Liberando portas..."
for PORT in 3000 3001 3002; do
    PID=$(sudo lsof -ti:${PORT} 2>/dev/null || true)
    if [ -n "$PID" ]; then
        sudo kill -9 $PID 2>/dev/null || true
        echo "      Porta ${PORT} liberada (PID: $PID)"
    fi
done

echo ""
echo "==================================================="
echo "  RESET CONCLUIDO!"
echo ""
echo "  Removido: containers, imagens e volumes da app"
echo "  Mantido:  Jenkins, Zabbix, rede, infra"
echo ""
echo "  Jenkins:  http://177.44.248.116:8082 (funcionando)"
echo "  Zabbix:   http://177.44.248.116:8080 (funcionando)"
echo "==================================================="

# Confirma que Jenkins e Zabbix continuam rodando
echo ""
echo "  Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || docker ps
echo ""
