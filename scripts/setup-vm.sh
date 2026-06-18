#!/bin/bash
set -eo pipefail

# ══════════════════════════════════════════════════════════════
# Setup da VM — provisiona TUDO do zero
#   - dependencias (Docker, Terraform, Node, Git)
#   - imagem do Jenkins (build UMA vez, depois fica em cache)
#   - Terraform: rede + Jenkins (configurado via JCasC) + app
#
# Apos rodar: Jenkins ja sobe configurado (admin/admin, job
# financas-pipeline com polling). Basta acessar e dar Build.
# ══════════════════════════════════════════════════════════════

REPO_URL="https://github.com/PedroScheid/gerencia-configuracao-financas.git"
PROJECT_DIR="/home/univates/financas"

echo ""
echo "==================================================="
echo "  Setup da Infraestrutura CI/CD"
echo "==================================================="
echo ""

# ── 1. Dependencias basicas ─────────────────────────────────
echo "[1/7] Instalando dependencias do sistema..."
sudo apt-get update -qq 2>&1 | tail -1 || echo "      AVISO: apt-get update com avisos"
sudo apt-get install -y -qq \
    apt-transport-https ca-certificates curl gnupg lsb-release \
    software-properties-common unzip git \
    2>&1 | tail -1 || echo "      AVISO: alguns pacotes podem nao ter instalado"
sudo apt-get install -y -qq ansible 2>&1 | tail -1 || {
    sudo apt-get install -y -qq python3-pip 2>&1 | tail -1 || true
    pip3 install ansible --break-system-packages 2>&1 | tail -1 || true
}
echo "      OK"

# ── 2. Docker ───────────────────────────────────────────────
echo "[2/7] Instalando Docker..."
if command -v docker &>/dev/null; then
    echo "      Docker ja instalado: $(docker --version)"
else
    curl -fsSL https://get.docker.com | sudo sh 2>&1 | tail -3 || {
        sudo apt-get install -y docker.io 2>&1 | tail -1 || true
    }
fi
sudo usermod -aG docker univates 2>/dev/null || true
sudo systemctl enable docker --now 2>/dev/null || true
if ! docker ps &>/dev/null; then
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
fi
if docker ps &>/dev/null; then
    echo "      Docker funcionando OK"
else
    echo "      ERRO CRITICO: Docker nao funciona. Abortando."
    exit 1
fi

# ── 3. Terraform ────────────────────────────────────────────
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

# ── 4. Node.js ──────────────────────────────────────────────
echo "[4/7] Instalando Node.js..."
if command -v node &>/dev/null; then
    echo "      Node.js ja instalado: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>&1 | tail -1
    sudo apt-get install -y -qq nodejs 2>&1 | tail -1
    echo "      Node.js $(node --version) instalado"
fi

# ── 5. Firewall ─────────────────────────────────────────────
echo "[5/7] Configurando firewall..."
for PORT in 22 3000 3001 3002 8082 50000; do
    sudo ufw allow ${PORT}/tcp >/dev/null 2>&1 || true
done
echo "y" | sudo ufw enable 2>/dev/null || true
echo "      Portas liberadas: 22, 3000-3002, 8082, 50000"

# ── 6. Sincronizar repositorio com o GitHub (FORCADO) ───────
echo "[6/7] Sincronizando repositorio com o GitHub (forcado)..."
if [ -d "${PROJECT_DIR}/.git" ]; then
    cd "${PROJECT_DIR}"
    git fetch origin main 2>&1 | tail -1 || echo "      AVISO: git fetch com avisos"
    git reset --hard origin/main 2>&1 | tail -1
    git clean -fd 2>&1 | tail -1 || true
    echo "      Repositorio sincronizado com origin/main"
else
    rm -rf "${PROJECT_DIR}" 2>/dev/null || true
    git clone "${REPO_URL}" "${PROJECT_DIR}" 2>&1 | tail -1
    echo "      Repositorio clonado"
fi
cd "${PROJECT_DIR}"
chmod +x scripts/*.sh 2>/dev/null || true

# Re-exec da versao mais recente do setup (trava evita loop)
if [ -z "${SETUP_REEXEC:-}" ]; then
    export SETUP_REEXEC=1
    echo "      Garantindo execucao da versao mais recente do setup..."
    exec bash "${PROJECT_DIR}/scripts/setup-vm.sh"
fi

# ── 7. Imagem do Jenkins + Terraform ────────────────────────
echo "[7/7] Preparando imagem do Jenkins e aplicando Terraform..."

# Builda a imagem custom do Jenkins UMA vez (fica em cache).
# Se ja existir, nao rebuilda (evita os ~9 min na hora da demo).
if docker image inspect financas-jenkins:latest &>/dev/null; then
    echo "      Imagem financas-jenkins:latest ja existe (cache) — pulando build."
else
    echo "      Buildando imagem financas-jenkins:latest (primeira vez, ~5-9 min)..."
    docker build -t financas-jenkins:latest "${PROJECT_DIR}/jenkins"
    echo "      Imagem buildada."
fi

cd "${PROJECT_DIR}/terraform"
rm -rf .terraform terraform.tfstate terraform.tfstate.backup 2>/dev/null || true

echo "      Inicializando Terraform..."
terraform init -input=false 2>&1 | tail -2

echo "      Aplicando infraestrutura (rede + Jenkins + app)..."
terraform apply -auto-approve -input=false

echo ""
echo "Aguardando Jenkins iniciar..."
sleep 10

echo ""
echo "==================================================="
echo "  CONTAINERS ATIVOS:"
echo "==================================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps

echo ""
echo "==================================================="
echo "  SETUP CONCLUIDO!"
echo ""
echo "  Jenkins: http://177.44.248.116:8082  (login: admin / admin)"
echo "  Job 'financas-pipeline' ja configurado — clique em Build Now."
echo "==================================================="
