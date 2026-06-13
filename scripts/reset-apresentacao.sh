#!/bin/bash
set -eo pipefail

# ══════════════════════════════════════════════════════════════
# Reset para Apresentacao (lado VM)
# Limpa APENAS os ambientes da aplicacao (containers, imagens,
# volumes) e dropa a tabela categoria. Mantem Jenkins e Zabbix.
#
# NOTA: este script NAO edita mais codigo na VM (migration, lint,
# cor). Essas reversoes agora sao feitas LOCALMENTE pelo
# reset-apresentacao.bat, que commita/pusha e dispara o build no
# Jenkins (que clona do GitHub). Editar codigo na VM sujaria o
# working tree e quebraria o git pull do setup.
# ══════════════════════════════════════════════════════════════

echo ""
echo "==================================================="
echo "  RESET PARA APRESENTACAO (limpeza de ambientes)"
echo "  (mantem Jenkins + Zabbix)"
echo "==================================================="
echo ""

# Dropa a tabela categoria nos bancos (antes de remover containers/volumes)
echo "[1/5] Removendo tabela 'categoria' dos bancos (migration 002)..."
for CONTAINER in financas-integracao financas-homologacao financas-producao; do
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        SQL="DROP TABLE IF EXISTS categoria; DELETE FROM schema_migrations WHERE filename='002_create_categorias.sql';"
        if docker exec ${CONTAINER} sh -c "sqlite3 \"\$DB_PATH\" \"${SQL}\"" 2>/dev/null; then
            echo "      Tabela removida em: ${CONTAINER}"
        else
            echo "      ${CONTAINER}: sqlite3 indisponivel (volume sera removido no passo 3)"
        fi
    fi
done

# Para e remove containers da aplicacao
echo "[2/5] Removendo containers da aplicacao..."
for CONTAINER in financas-integracao financas-homologacao financas-producao; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        docker stop ${CONTAINER} 2>/dev/null || true
        docker rm ${CONTAINER} 2>/dev/null || true
        echo "      Removido: ${CONTAINER}"
    fi
done

# Remove imagens da aplicacao
echo "[3/5] Removendo imagens da aplicacao..."
for TAG in latest homolog production; do
    if docker image inspect financas-app:${TAG} &>/dev/null; then
        docker rmi financas-app:${TAG} 2>/dev/null || true
        echo "      Removida: financas-app:${TAG}"
    fi
done
docker images --format '{{.Repository}}:{{.Tag}}' | grep '^financas-app:' | xargs -r docker rmi 2>/dev/null || true

# Remove volumes da aplicacao (dados SQLite)
echo "[4/5] Removendo volumes da aplicacao..."
for VOL in financas-integracao-data financas-homologacao-data financas-producao-data; do
    if docker volume inspect ${VOL} &>/dev/null; then
        docker volume rm ${VOL} 2>/dev/null || true
        echo "      Removido: ${VOL}"
    fi
done

# Libera portas da aplicacao
echo "[5/5] Liberando portas..."
for PORT in 3000 3001 3002; do
    PID=$(sudo lsof -ti:${PORT} 2>/dev/null || true)
    if [ -n "$PID" ]; then
        sudo kill -9 $PID 2>/dev/null || true
        echo "      Porta ${PORT} liberada (PID: $PID)"
    fi
done

echo ""
echo "==================================================="
echo "  RESET (VM) CONCLUIDO!"
echo ""
echo "  Removido: containers, imagens, volumes, tabela categoria"
echo "  Mantido: Jenkins, Zabbix, rede, infra"
echo "  (Cor verde e remocao da migration vem pelo build do Jenkins)"
echo ""
echo "  Jenkins:  http://177.44.248.116:8082 (funcionando)"
echo "  Zabbix:   http://177.44.248.116:8080 (funcionando)"
echo "==================================================="

echo ""
echo "  Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || docker ps
echo ""
