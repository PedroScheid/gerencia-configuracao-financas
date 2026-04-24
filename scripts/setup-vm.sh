#!/bin/bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════
# Setup da VM — instala tudo e sobe a infraestrutura
# Pode ser executado remotamente via SSH
# ══════════════════════════════════════════════════════════════

REPO_URL="https://github.com/PedroScheid/gerencia-configuracao-financas.git"
PROJECT_DIR="/home/univates/financas"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Setup da Infraestrutura CI/CD"
echo "═══════════════════════════════════════════════════"
echo ""

# ── 1. Instalar dependências básicas ─────────────────────────
echo "[1/8] Instalando dependências do sistema..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    git \
    ansible \
    2>&1 | tail -1

echo "      OK"

# ── 2. Instalar Docker ──────────────────────────────────────
echo "[2/8] Instalando Docker..."
if command -v docker &>/dev/null; then
    echo "      Docker já instalado: $(docker --version)"
else
    curl -fsSL https://get.docker.com | sudo sh 2>&1 | tail -3
    sudo usermod -aG docker univates
    echo "      Docker instalado com sucesso"
fi
sudo systemctl enable docker --now 2>/dev/null || true

# ── 3. Instalar Terraform ───────────────────────────────────
echo "[3/8] Instalando Terraform..."
if command -v terraform &>/dev/null; then
    echo "      Terraform já instalado: $(terraform version -json 2>/dev/null | head -1 || terraform version | head -1)"
else
    TERRAFORM_VERSION="1.7.0"
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip
    sudo unzip -o /tmp/terraform.zip -d /usr/local/bin/ >/dev/null
    rm -f /tmp/terraform.zip
    echo "      Terraform ${TERRAFORM_VERSION} instalado"
fi

# ── 4. Instalar Node.js ─────────────────────────────────────
echo "[4/8] Instalando Node.js..."
if command -v node &>/dev/null; then
    echo "      Node.js já instalado: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>&1 | tail -1
    sudo apt-get install -y -qq nodejs 2>&1 | tail -1
    echo "      Node.js $(node --version) instalado"
fi

# ── 5. Configurar Firewall ──────────────────────────────────
echo "[5/8] Configurando firewall..."
sudo ufw allow 22/tcp   >/dev/null 2>&1 || true
sudo ufw allow 3000/tcp >/dev/null 2>&1 || true
sudo ufw allow 3001/tcp >/dev/null 2>&1 || true
sudo ufw allow 3002/tcp >/dev/null 2>&1 || true
sudo ufw allow 8080/tcp >/dev/null 2>&1 || true
sudo ufw allow 8082/tcp >/dev/null 2>&1 || true
sudo ufw allow 10051/tcp >/dev/null 2>&1 || true
echo "y" | sudo ufw enable 2>/dev/null || true
echo "      Portas liberadas: 22, 3000-3002, 8080, 8082, 10051"

# ── 6. Clonar/Atualizar repositório ─────────────────────────
echo "[6/8] Preparando repositório..."
if [ -d "${PROJECT_DIR}/.git" ]; then
    cd "${PROJECT_DIR}"
    git pull origin main 2>&1 | tail -1
    echo "      Repositório atualizado"
else
    sudo rm -rf "${PROJECT_DIR}"
    git clone "${REPO_URL}" "${PROJECT_DIR}"
    echo "      Repositório clonado"
fi
cd "${PROJECT_DIR}"
chmod +x scripts/*.sh 2>/dev/null || true

# ── 7. Rodar Ansible (registro formal do provisionamento) ───
echo "[7/8] Executando Ansible playbook..."
cd "${PROJECT_DIR}/ansible"
ansible-playbook -i inventory.ini playbook.yml --connection=local 2>&1 | grep -E "(ok=|changed=|TASK|PLAY|fatal|msg)" || true
echo "      Ansible concluído"

# ── 8. Terraform — sobe Jenkins + Zabbix ────────────────────
echo "[8/8] Executando Terraform..."
cd "${PROJECT_DIR}/terraform"

# Garante que docker está acessível (pode precisar de newgrp)
if ! docker ps &>/dev/null; then
    echo "      Aplicando permissões Docker (newgrp)..."
    sudo chmod 666 /var/run/docker.sock
fi

# Cria a rede Docker
docker network create financas-network 2>/dev/null || true

terraform init -input=false 2>&1 | tail -2
terraform apply -auto-approve -input=false -var="jenkins_enabled=true" 2>&1 | tail -10

# ── Aguardar containers subirem ──────────────────────────────
echo ""
echo "Aguardando containers iniciarem..."
sleep 15

# ── Mostrar status ───────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "  CONTAINERS ATIVOS:"
echo "═══════════════════════════════════════════════════"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════════════════"
echo "  SETUP CONCLUÍDO!"
echo ""
echo "  Jenkins: http://177.44.248.116:8082"
echo "  Zabbix:  http://177.44.248.116:8080"
echo ""
echo "  Senha inicial do Jenkins:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "  (Jenkins ainda iniciando, aguarde 1 min e rode: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)"
echo ""
echo "  Zabbix login: Admin / zabbix"
echo "═══════════════════════════════════════════════════"
