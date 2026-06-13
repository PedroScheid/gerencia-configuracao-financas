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

# Dropa a tabela categoria nos bancos (antes de remover containers/volumes)
echo "[1/8] Removendo tabela 'categoria' dos bancos (migration 002)..."
for CONTAINER in financas-integracao financas-homologacao financas-producao; do
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        SQL="DROP TABLE IF EXISTS categoria; DELETE FROM schema_migrations WHERE filename='002_create_categorias.sql';"
        if docker exec ${CONTAINER} sh -c "sqlite3 \"\$DB_PATH\" \"${SQL}\"" 2>/dev/null; then
            echo "      Tabela removida em: ${CONTAINER}"
        else
            echo "      ${CONTAINER}: sqlite3 indisponivel (volume sera removido no passo 4)"
        fi
    fi
done

# Para e remove containers da aplicacao
echo "[2/8] Removendo containers da aplicacao..."
for CONTAINER in financas-integracao financas-homologacao financas-producao; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        docker stop ${CONTAINER} 2>/dev/null || true
        docker rm ${CONTAINER} 2>/dev/null || true
        echo "      Removido: ${CONTAINER}"
    fi
done

# Remove imagens da aplicacao
echo "[3/8] Removendo imagens da aplicacao..."
for TAG in latest homolog production; do
    if docker image inspect financas-app:${TAG} &>/dev/null; then
        docker rmi financas-app:${TAG} 2>/dev/null || true
        echo "      Removida: financas-app:${TAG}"
    fi
done
# Remove imagens com tag de build number
docker images --format '{{.Repository}}:{{.Tag}}' | grep '^financas-app:' | xargs -r docker rmi 2>/dev/null || true

# Remove volumes da aplicacao (dados SQLite)
echo "[4/8] Removendo volumes da aplicacao..."
for VOL in financas-integracao-data financas-homologacao-data financas-producao-data; do
    if docker volume inspect ${VOL} &>/dev/null; then
        docker volume rm ${VOL} 2>/dev/null || true
        echo "      Removido: ${VOL}"
    fi
done

# Reseta codigo para estado inicial da apresentacao
echo "[5/8] Removendo migration 002 (se existir)..."
if [ -f /home/univates/financas/backend/src/database/migrations/002_create_categorias.sql ]; then
    rm /home/univates/financas/backend/src/database/migrations/002_create_categorias.sql
    echo "      Removida: 002_create_categorias.sql"
else
    echo "      Ja nao existe"
fi

echo "[6/8] Removendo erro de lint (se existir)..."
FIRST_LINE=$(head -1 /home/univates/financas/backend/src/index.ts)
if echo "$FIRST_LINE" | grep -q "minha_variavel_errada"; then
    sed -i '1d' /home/univates/financas/backend/src/index.ts
    echo "      Erro de lint removido"
else
    echo "      Nenhum erro de lint encontrado"
fi

echo "[7/8] Restaurando cor verde no layout..."
sed -i 's/--primary: #1565c0/--primary: #16a34a/g; s/--primary-dark: #0d47a1/--primary-dark: #15803d/g; s/--primary-light: #e3f2fd/--primary-light: #dcfce7/g' /home/univates/financas/frontend/src/index.css
sed -i 's/#1565c0/#16a34a/g; s/#0d47a1/#15803d/g; s/#0a2463/#064e3b/g' /home/univates/financas/frontend/src/index.css
echo "      Cor restaurada para verde"

# Libera portas da aplicacao
echo "[8/8] Liberando portas..."
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
echo "  Removido: containers, imagens, volumes, tabela categoria, migration 002"
echo "  Restaurado: cor verde, sem erro de lint"
echo "  Mantido: Jenkins, Zabbix, rede, infra"
echo ""
echo "  Jenkins:  http://177.44.248.116:8082 (funcionando)"
echo "  Zabbix:   http://177.44.248.116:8080 (funcionando)"
echo "==================================================="

# Confirma que Jenkins e Zabbix continuam rodando
echo ""
echo "  Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || docker ps
echo ""
