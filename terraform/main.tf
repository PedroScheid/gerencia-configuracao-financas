terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# ══════════════════════════════════════════════════════════════
''''''# Este Terraform provisiona TODA a infraestrutura do zero:
#   - rede financas-network
#   - Jenkins (a partir de imagem pre-buildada financas-jenkins:latest)
#   - volumes e containers da aplicacao (homolog/prod)
#
# A imagem do Jenkins (jenkins/Dockerfile) ja vem com git, rsync,
# node, docker-cli, plugins e Configuration as Code (admin/admin +
# seed job financas-pipeline). Ela e buildada UMA vez pelo
# setup-vm.sh e fica em cache (keep_locally), entao o apply so
# sobe o container — sem esperar build na hora da apresentacao.
# ══════════════════════════════════════════════════════════════

# ── Network ──────────────────────────────────────────────────
resource "docker_network" "financas" {
  name = "financas-network"
}

# ── Volumes ──────────────────────────────────────────────────
resource "docker_volume" "jenkins_data" {
  name = "jenkins-data"
}

resource "docker_volume" "integracao_data" {
  name = "financas-integracao-data"
}

resource "docker_volume" "homologacao_data" {
  name  = "financas-homologacao-data"
  count = var.homologacao_enabled ? 1 : 0
}

resource "docker_volume" "producao_data" {
  name  = "financas-producao-data"
  count = var.producao_enabled ? 1 : 0
}

# ── Jenkins Container (imagem pre-buildada) ──────────────────
resource "docker_image" "jenkins" {
  count        = var.jenkins_enabled ? 1 : 0
  name         = "financas-jenkins:latest"
  keep_locally = true
}

resource "docker_container" "jenkins" {
  count = var.jenkins_enabled ? 1 : 0

  name  = "jenkins"
  image = docker_image.jenkins[0].image_id

  ports {
    internal = 8080
    external = 8082
  }

  ports {
    internal = 50000
    external = 50000
  }

  volumes {
    volume_name    = docker_volume.jenkins_data.name
    container_path = "/var/jenkins_home"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"
  user    = "root"

  env = [
    "CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc/jenkins.yaml",
    "JAVA_OPTS=-Djenkins.install.runSetupWizard=false"
  ]
}

# ── Application Containers ──────────────────────────────────
# Integracao: criada pelo pipeline Jenkins (docker run no deploy).

# Homologação
resource "docker_container" "homologacao" {
  count = var.homologacao_enabled ? 1 : 0

  name  = "financas-homologacao"
  image = "financas-app:homolog"

  ports {
    internal = 3000
    external = 3002
  }

  volumes {
    volume_name    = docker_volume.homologacao_data[0].name
    container_path = "/data"
  }

  env = [
    "NODE_ENV=homologation",
    "PORT=3000"
  ]

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"
}

# Produção
resource "docker_container" "producao" {
  count = var.producao_enabled ? 1 : 0

  name  = "financas-producao"
  image = "financas-app:production"

  ports {
    internal = 3000
    external = 3000
  }

  volumes {
    volume_name    = docker_volume.producao_data[0].name
    container_path = "/data"
  }

  env = [
    "NODE_ENV=production",
    "PORT=3000"
  ]

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"
}
