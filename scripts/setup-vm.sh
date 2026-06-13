#!/bin/bash
set -eo pipefail

# ══════════════════════════════════════════════════════════════
# Setup da VM — prepara a aplicacao
#
# IMPORTANTE: Jenkins e Zabbix NAO sao tocados por este script.
# Eles rodam de forma permanente (restart=unless-stopped), ja
# configurados. Este setup apenas instala dependencias, atualiza
# o repositorio e aplica o Terraform da APLICACAO (rede ja
# existente + volumes/containers de homolog/prod quando habilitados).
# ══════════════════════════════════════════════════════════════

REPO_URL="https://github.com/PedroScheid/gerencia-configuracao-financas.git"
PROJECT_DIR="/home/univates/financas"

echo ""
echo "==================================================="
echo "  Setup da Aplicacao"
echo "  (Jenkins e Zabbix permanecem rodando, intocados)"
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

# ── 7. Terraform — aplica a APLICACAO (nao toca Jenkins/Zabbix) ─
echo "[7/7] Executando Terraform (aplicacao)..."
cd "${PROJECT_DIR}/terraform"

# Limpa estado anterior se existir (re-run seguro)
rm -rf .terraform terraform.tfstate terraform.tfstate.backup 2>/dev/null || true

# Garante que a rede financas-network exista (Jenkins/Zabbix ja a usam).
# Se por algum motivo nao existir, cria — sem derrubar nada.
if ! docker network inspect financas-network &>/dev/null; then
    echo "      Rede financas-network nao encontrada — criando..."
    docker network create financas-network 2>/dev/null || true
fi

echo "      Inicializando Terraform..."
terraform init -input=false 2>&1 | tail -2

echo "      Aplicando infraestrutura da aplicacao..."
terraform apply -auto-approve -input=false

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
echo "  Jenkins: http://177.44.248.116:8082  (ja rodando)"
echo "  Zabbix:  http://177.44.248.116:8080  (ja rodando)"
echo ""
echo "  Integracao sobe via build no Jenkins (porta 3001)."
echo "  Homologacao/Producao via promote-homolog / promote-prod."
echo "==================================================="
