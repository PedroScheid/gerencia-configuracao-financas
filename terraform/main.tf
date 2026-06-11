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
  name = "financas-homologacao-data"
  count = var.homologacao_enabled ? 1 : 0
}

resource "docker_volume" "producao_data" {
  name = "financas-producao-data"
  count = var.producao_enabled ? 1 : 0
}

# ── Jenkins Container ────────────────────────────────────────
resource "docker_image" "jenkins" {
  name         = "jenkins/jenkins:lts"
  keep_locally = true
  count        = var.jenkins_enabled ? 1 : 0
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

  volumes {
    host_path      = "/home/univates/financas"
    container_path = "/repo"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"

  # Jenkins needs Docker CLI inside the container
  user = "root"

  provisioner "local-exec" {
    command = "sleep 10 && docker exec jenkins bash -c 'apt-get update && apt-get install -y docker.io rsync' || true"
  }
}

# ── Zabbix Containers ───────────────────────────────────────

resource "docker_image" "zabbix_server" {
  name         = "zabbix/zabbix-server-pgsql:alpine-7.0-latest"
  keep_locally = true
}

resource "docker_image" "zabbix_web" {
  name         = "zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest"
  keep_locally = true
}

resource "docker_image" "zabbix_agent" {
  name         = "zabbix/zabbix-agent:alpine-7.0-latest"
  keep_locally = true
}

resource "docker_image" "postgres" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

resource "docker_volume" "zabbix_db_data" {
  name = "zabbix-db-data"
}

resource "docker_container" "zabbix_db" {
  name  = "zabbix-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=zabbix",
    "POSTGRES_USER=zabbix",
    "POSTGRES_PASSWORD=zabbix_pwd"
  ]

  volumes {
    volume_name    = docker_volume.zabbix_db_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"
}

resource "docker_container" "zabbix_server" {
  name  = "zabbix-server"
  image = docker_image.zabbix_server.image_id

  depends_on = [docker_container.zabbix_db]

  env = [
    "DB_SERVER_HOST=zabbix-postgres",
    "POSTGRES_DB=zabbix",
    "POSTGRES_USER=zabbix",
    "POSTGRES_PASSWORD=zabbix_pwd"
  ]

  ports {
    internal = 10051
    external = 10051
  }

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"
}

resource "docker_container" "zabbix_web" {
  name  = "zabbix-web"
  image = docker_image.zabbix_web.image_id

  depends_on = [docker_container.zabbix_server]

  env = [
    "ZBX_SERVER_HOST=zabbix-server",
    "DB_SERVER_HOST=zabbix-postgres",
    "POSTGRES_DB=zabbix",
    "POSTGRES_USER=zabbix",
    "POSTGRES_PASSWORD=zabbix_pwd",
    "PHP_TZ=America/Sao_Paulo"
  ]

  ports {
    internal = 8080
    external = 8080
  }

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"
}

resource "docker_container" "zabbix_agent" {
  name  = "zabbix-agent"
  image = docker_image.zabbix_agent.image_id

  depends_on = [docker_container.zabbix_server]

  env = [
    "ZBX_SERVER_HOST=zabbix-server",
    "ZBX_HOSTNAME=financas-host"
  ]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.financas.name
  }

  restart = "unless-stopped"
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
