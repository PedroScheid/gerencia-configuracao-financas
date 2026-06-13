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
echo "[1/7] Instalando dependencias do sistema..."
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

# Ansible separado
sudo apt-get install -y -qq ansible 2>&1 | tail -1 || {
    echo "      Ansible nao disponivel via apt, tentando pip..."
    sudo apt-get install -y -qq python3-pip 2>&1 | tail -1 || true
    pip3 install ansible --break-system-packages 2>&1 | tail -1 || true
}
echo "      OK"

# ── 2. Instalar Docker ──────────────────────────────────────
echo "[2/7] Instalando Docker..."
if command -v docker &>/dev/null; then
    echo "      Docker ja instalado: $(docker --version)"
else
    curl -fsSL https://get.docker.com | sudo sh 2>&1 | tail -3 || {
        echo "      AVISO: get.docker.com falhou, tentando apt..."
        sudo apt-get install -y docker.io 2>&1 | tail -1 || true
    }
    echo "      Docker instalado"
fi
sudo usermod -aG docker univates 2>/dev/null || true
sudo systemctl enable docker --now 2>/dev/null || true

# Garantir acesso ao docker socket
if ! docker ps &>/dev/null; then
    echo "      Ajustando permissoes do Docker socket..."
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
fi
if docker ps &>/dev/null; then
    echo "      Docker funcionando OK"
else
    echo "      ERRO CRITICO: Docker nao funciona. Abortando."
    exit 1
fi

# ── 3. Instalar Terraform ───────────────────────────────────
echo "[3/7] Instalando Terraform..."
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
echo "[4/7] Instalando Node.js..."
if command -v node &>/dev/null; then
    echo "      Node.js ja instalado: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>&1 | tail -1
    sudo apt-get install -y -qq nodejs 2>&1 | tail -1
    echo "      Node.js $(node --version) instalado"
fi

# ── 5. Configurar Firewall ──────────────────────────────────
echo "[5/7] Configurando firewall..."
for PORT in 22 3000 3001 3002 8080 8082 10051; do
    sudo ufw allow ${PORT}/tcp >/dev/null 2>&1 || true
done
echo "y" | sudo ufw enable 2>/dev/null || true
echo "      Portas liberadas: 22, 3000-3002, 8080, 8082, 10051"

# ── 6. Clonar/Atualizar repositorio ─────────────────────────
echo "[6/7] Preparando repositorio..."
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

# ── 7. Terraform — sobe Jenkins + Zabbix ────────────────────
echo "[7/7] Executando Terraform..."
cd "${PROJECT_DIR}/terraform"

# Limpa estado anterior se existir (re-run seguro)
rm -rf .terraform terraform.tfstate terraform.tfstate.backup 2>/dev/null || true

# Remove containers/networks antigos pra Terraform criar do zero
echo "      Parando containers antigos..."
docker stop jenkins zabbix-web zabbix-server zabbix-agent zabbix-postgres 2>/dev/null || true
docker rm -f jenkins zabbix-web zabbix-server zabbix-agent zabbix-postgres 2>/dev/null || true

# Recria o volume do Jenkins para o JCasC (admin/admin + seed job) ser
# aplicado do zero a cada setup. Garante config 100% reproduzivel via codigo.
# (O reset-apresentacao NAO mexe neste volume; so o setup recria.)
echo "      Recriando volume do Jenkins (aplica JCasC do zero)..."
docker volume rm jenkins-data 2>/dev/null || true

# Remove a rede de forma confiavel: desconecta qualquer container ainda
# ligado a ela antes do 'network rm' (senao a rede sobrevive e o
# terraform apply falha com "network already exists").
if docker network inspect financas-network &>/dev/null; then
    echo "      Desconectando containers da rede financas-network..."
    for C in $(docker network inspect financas-network --format '{{range .Containers}}{{.Name}} {{end}}'); do
        docker network disconnect -f financas-network "$C" 2>/dev/null || true
    done
    docker network rm financas-network 2>/dev/null || true
fi

# Verificacao final: se a rede ainda existir, aborta com mensagem clara
if docker network inspect financas-network &>/dev/null; then
    echo "      ERRO: nao foi possivel remover a rede financas-network."
    echo "      Rode manualmente: docker rm -f \$(docker ps -aq) && docker network rm financas-network"
    exit 1
fi
echo "      Rede financas-network limpa"

echo "      Inicializando Terraform..."
terraform init -input=false 2>&1 | tail -2

echo "      Aplicando infraestrutura..."
terraform apply -auto-approve -input=false -var="jenkins_enabled=true"

# ── Aguardar containers subirem ──────────────────────────────
echo ""
echo "Aguardando containers iniciarem..."
sleep 15

# ── Instalar Docker CLI + Node.js dentro do Jenkins ──────────
echo "Instalando Docker CLI e Node.js no Jenkins (pode levar 1-2 min)..."
docker exec jenkins bash -c '
    apt-get update -qq && \
    apt-get install -y -qq docker.io curl rsync git && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y -qq nodejs && \
    echo "git $(git --version) instalado" && \
    echo "rsync $(rsync --version | head -1) instalado" && \
    echo "Node.js $(node --version) instalado" && \
    echo "npm $(npm --version) instalado"
' 2>&1 | grep -E "(instalado|Err|error)" || true

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
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "  (aguarde 1 min e rode: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)"
echo ""
echo "  Zabbix login: Admin / zabbix"
echo "==================================================="
