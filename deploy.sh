#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Script de implantação automática na VM
# VM: univates@177.44.248.116
# =============================================================================
set -e

SERVER="univates@177.44.248.116"
REMOTE_DIR="/home/univates/financas"

echo "==> [1/5] Build do frontend..."
cd frontend
npm install
npm run build
cd ..

echo "==> [2/5] Build do backend..."
cd backend
npm install
npm run build
cd ..

echo "==> [3/5] Copiando arquivos para a VM..."
ssh "$SERVER" "mkdir -p $REMOTE_DIR/frontend $REMOTE_DIR/backend"

# Copia o build do backend
scp -r backend/dist      "$SERVER:$REMOTE_DIR/backend/"
scp    backend/package.json "$SERVER:$REMOTE_DIR/backend/"

# Copia o build do frontend
scp -r frontend/dist     "$SERVER:$REMOTE_DIR/frontend/"

# Copia configurações
scp ecosystem.config.js  "$SERVER:$REMOTE_DIR/"

echo "==> [4/5] Instalando dependências de produção na VM..."
ssh "$SERVER" "cd $REMOTE_DIR/backend && npm install --omit=dev"

echo "==> [5/5] Iniciando/Reiniciando aplicação com PM2..."
ssh "$SERVER" "
  cd $REMOTE_DIR
  pm2 delete financas 2>/dev/null || true
  pm2 start ecosystem.config.js
  pm2 save
"

echo ""
echo "============================================"
echo "  Deploy concluído com sucesso!"
echo "  Acesse: http://177.44.248.116:3000"
echo "============================================"
