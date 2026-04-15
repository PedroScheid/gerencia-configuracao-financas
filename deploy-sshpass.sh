#!/usr/bin/env bash
# =============================================================================
# deploy-sshpass.sh — Deploy automatizado usando sshpass (senha: pedro123)
# =============================================================================
set -e

SERVER="univates@177.44.248.116"
REMOTE_DIR="/home/univates/financas"
SSHPASS="sshpass -p 'pedro123'"

# 1. Build do frontend
cd frontend
npm install
npm run build
cd ..

# 2. Build do backend
cd backend
npm install
npm run build
cd ..

# 3. Copiando arquivos para a VM
$SSHPASS ssh "$SERVER" "mkdir -p $REMOTE_DIR/frontend $REMOTE_DIR/backend"
$SSHPASS scp -r backend/dist         "$SERVER:$REMOTE_DIR/backend/"
$SSHPASS scp    backend/package.json "$SERVER:$REMOTE_DIR/backend/"
$SSHPASS scp    backend/.env         "$SERVER:$REMOTE_DIR/backend/"
$SSHPASS scp -r frontend/dist        "$SERVER:$REMOTE_DIR/frontend/"
$SSHPASS scp ecosystem.config.js     "$SERVER:$REMOTE_DIR/"

# 4. Instala dependências de produção na VM
$SSHPASS ssh "$SERVER" "cd $REMOTE_DIR/backend && npm install --omit=dev"

# 5. Inicia/Reinicia aplicação com PM2
$SSHPASS ssh "$SERVER" "\
  cd $REMOTE_DIR && \
  pm2 delete financas 2>/dev/null || true && \
  pm2 start ecosystem.config.js && \
  pm2 save
"

echo ""
echo "============================================"
echo "  Deploy concluído com sucesso!"
echo "  Acesse: http://177.44.248.116:3000"
echo "============================================"
