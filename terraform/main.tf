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
# NOTA SOBRE JENKINS E ZABBIX
# ──────────────────────────────────────────────────────────────
# Jenkins e Zabbix sao provisionados UMA VEZ e ficam rodando
# permanentemente (restart=unless-stopped). Eles foram retirados
# do controle deste Terraform para que o setup-vm.sh / reset NAO
# os recriem nem derrubem na hora da apresentacao (o build da
# imagem do Jenkins levava ~9 min, inviavel ao vivo).
#
# Este Terraform agora gerencia apenas: a rede, os volumes da
# aplicacao e os containers de homologacao/producao.
#
# Os blocos originais de Jenkins e Zabbix ficam COMENTADOS ao
# final deste arquivo, como referencia de como foram criados.
# ══════════════════════════════════════════════════════════════

# ── Network ──────────────────────────────────────────────────
# Importante: a rede ja existe (criada no provisionamento inicial
# do Jenkins/Zabbix). Para o Terraform nao tentar recria-la, ela
# deve ser importada OU mantida fora deste apply. Como Jenkins e
# Zabbix usam 'financas-network', NAO a recriamos aqui.
# A app usa a mesma rede ja existente via data source:
data "docker_network" "financas" {
  name = "financas-network"
}

# ── Volumes da aplicacao ─────────────────────────────────────
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

# ── Application Containers ──────────────────────────────────

# Integration (managed by Jenkins pipeline, defined here for reference)
# The Jenkins pipeline handles the integration container directly

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
    name = data.docker_network.financas.name
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
    name = data.docker_network.financas.name
  }

  restart = "unless-stopped"
}

# ══════════════════════════════════════════════════════════════
# REFERENCIA — Infra permanente (Jenkins + Zabbix)
# ──────────────────────────────────────────────────────────────
# Os blocos abaixo documentam como Jenkins e Zabbix foram
# provisionados originalmente. Ficam COMENTADOS porque rodam
# de forma permanente, fora deste apply. Para reprovisiona-los
# do zero (ex.: VM nova), descomente e rode um 'terraform apply'
# DEDICADO, fora do fluxo da apresentacao.
#
# # resource "docker_network" "financas" {
# #   name = "financas-network"
# # }
# #
# # resource "docker_volume" "jenkins_data" {
# #   name = "jenkins-data"
# # }
# #
# # resource "docker_image" "jenkins" {
# #   name = "jenkins/jenkins:lts"
# #   keep_locally = true
# # }
# #
# # resource "docker_container" "jenkins" {
# #   name  = "jenkins"
# #   image = docker_image.jenkins.image_id
# #   ports { internal = 8080  external = 8082 }
# #   ports { internal = 50000 external = 50000 }
# #   volumes { volume_name = docker_volume.jenkins_data.name  container_path = "/var/jenkins_home" }
# #   volumes { host_path = "/var/run/docker.sock"  container_path = "/var/run/docker.sock" }
# #   networks_advanced { name = docker_network.financas.name }
# #   restart = "unless-stopped"
# #   user = "root"
# # }
# #
# # resource "docker_container" "zabbix_db"     { ... postgres:15-alpine ...        }
# # resource "docker_container" "zabbix_server" { ... porta 10051 ...               }
# # resource "docker_container" "zabbix_web"    { ... porta 8080  ...               }
# # resource "docker_container" "zabbix_agent"  { ... ZBX_HOSTNAME=financas-host ... }
#
# (Versao completa destes blocos esta no historico do git.)
# ══════════════════════════════════════════════════════════════
