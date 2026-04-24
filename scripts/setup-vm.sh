#!/bin/bash
set -eo pipefail

# ══════════════════════════════════════════════════════════════
# Setup da VM — instala tudo e sobe a infraestrutura
# Pode ser executado remotamente via SSH
# ══════════════════════════════════════════════════════════════

REPO_URL="https://github.com/PedroScheid/gerencia-configuracao-financas.git"
PROJECT_DIR="/home/univates/financas"

echo ""
echo "==================================================="
echo "  Setup da Infraestrutura CI/CD"
echo "==================================================="
echo ""

# ── 1. Instalar dependencias basicas ─────────────────────────
echo "[1/8] Instalando dependencias do sistema..."
sudo apt-get update -qq 2>&1 | tail -1 || echo "      AVISO: apt-get update com avisos (continuando...)"
sudo apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    git \
    2>&1 | tail -1 || echo "      AVISO: alguns pacotes podem nao ter instalado"

# Ansible separado (pode nao estar no repo padrao)
sudo apt-get install -y -qq ansible 2>&1 | tail -1 || {
    echo "      Ansible nao disponivel via apt, tentando pip..."
    sudo apt-get install -y -qq python3-pip 2>&1 | tail -1 || true
    pip3 install ansible --break-system-packages 2>&1 | tail -1 || true
}
echo "      OK"

# ── 2. Instalar Docker ──────────────────────────────────────
echo "[2/8] Instalando Docker..."
if command -v docker &>/dev/null; then
    echo "      Docker ja instalado: $(docker --version)"
else
    curl -fsSL https://get.docker.com | sudo sh 2>&1 | tail -3 || {
        echo "      AVISO: Instalacao Docker via get.docker.com falhou"
        echo "      Tentando via apt..."
        sudo apt-get install -y docker.io 2>&1 | tail -1 || true
    }
    echo "      Docker instalado"
fi

# Adicionar usuario ao grupo docker (pode falhar por falta de permissao)
sudo usermod -aG docker univates 2>/dev/null || echo "      AVISO: usermod nao permitido (verificando se docker ja funciona...)"
sudo systemctl enable docker --now 2>/dev/null || true

# Garantir acesso ao docker socket
if ! docker ps &>/dev/null; then
    echo "      Ajustando permissoes do Docker socket..."
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
fi

# Verificar se docker funciona agora
if docker ps &>/dev/null; then
    echo "      Docker funcionando OK"
else
    echo "      ERRO: Docker nao esta acessivel. Verifique permissoes."
    echo "      Tentando chmod no socket..."
    sudo chmod 666 /var/run/docker.sock || true
    if docker ps &>/dev/null; then
        echo "      Docker funcionando apos chmod"
    else
        echo "      ERRO CRITICO: Docker nao funciona. Abortando."
        exit 1
    fi
fi

# ── 3. Instalar Terraform ───────────────────────────────────
echo "[3/8] Instalando Terraform..."
if command -v terraform &>/dev/null; then
    echo "      Terraform ja instalado: $(terraform version | head -1)"
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
    echo "      Node.js ja instalado: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>&1 | tail -1
    sudo apt-get install -y -qq nodejs 2>&1 | tail -1
    echo "      Node.js $(node --version) instalado"
fi

# ── 5. Configurar Firewall ──────────────────────────────────
echo "[5/8] Configurando firewall..."
for PORT in 22 3000 3001 3002 8080 8082 10051; do
    sudo ufw allow ${PORT}/tcp >/dev/null 2>&1 || true
done
echo "y" | sudo ufw enable 2>/dev/null || true
echo "      Portas liberadas: 22, 3000-3002, 8080, 8082, 10051"

# ── 6. Clonar/Atualizar repositorio ─────────────────────────
echo "[6/8] Preparando repositorio..."
if [ -d "${PROJECT_DIR}/.git" ]; then
    cd "${PROJECT_DIR}"
    git pull origin main 2>&1 | tail -1 || echo "      AVISO: git pull falhou (usando versao local)"
    echo "      Repositorio atualizado"
else
    rm -rf "${PROJECT_DIR}" 2>/dev/null || true
    git clone "${REPO_URL}" "${PROJECT_DIR}" 2>&1 | tail -1
    echo "      Repositorio clonado"
fi
cd "${PROJECT_DIR}"
chmod +x scripts/*.sh 2>/dev/null || true

# ── 7. Rodar Ansible (registro formal do provisionamento) ───
echo "[7/8] Executando Ansible playbook..."
if command -v ansible-playbook &>/dev/null; then
    cd "${PROJECT_DIR}/ansible"
    ansible-playbook -i inventory.ini playbook.yml --connection=local 2>&1 | grep -E "(ok=|changed=|TASK|PLAY|fatal|msg)" || true
    echo "      Ansible concluido"
else
    echo "      AVISO: ansible-playbook nao encontrado, pulando (ferramentas ja instaladas manualmente)"
fi

# ── 8. Terraform — sobe Jenkins + Zabbix ────────────────────
echo "[8/8] Executando Terraform..."
cd "${PROJECT_DIR}/terraform"

# Cria a rede Docker
docker network create financas-network 2>/dev/null || true

terraform init -input=false 2>&1 | tail -2
terraform apply -auto-approve -input=false -var="jenkins_enabled=true" 2>&1 | tail -15

# ── Aguardar containers subirem ──────────────────────────────
echo ""
echo "Aguardando containers iniciarem..."
sleep 15

# ── Mostrar status ───────────────────────────────────────────
echo ""
echo "==================================================="
echo "  CONTAINERS ATIVOS:"
echo "==================================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps

echo ""
echo "==================================================="
echo "  SETUP CONCLUIDO!"
echo ""
echo "  Jenkins: http://177.44.248.116:8082"
echo "  Zabbix:  http://177.44.248.116:8080"
echo ""
echo "  Senha inicial do Jenkins:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "  (Jenkins ainda iniciando, aguarde 1 min e rode: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)"
echo ""
echo "  Zabbix login: Admin / zabbix"
echo "==================================================="
