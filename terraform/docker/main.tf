terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# Network
resource "docker_network" "devops_network" {
  name = "devops-network"
}

# Volume for PostgreSQL data persistence
resource "docker_volume" "postgres_data" {
  name = "postgres-data"
}

# PostgreSQL Container
resource "docker_container" "postgres" {
  image = "postgres:13"
  name  = "devops-postgres"

  networks_advanced {
    name = docker_network.devops_network.name
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  env = [
    "POSTGRES_USER=admin",
    "POSTGRES_PASSWORD=admin",
    "POSTGRES_DB=devops_class"
  ]

  ports {
    internal = 5432
    external = 5432
  }
}

# Build the NodeJS application image
resource "docker_image" "nodejs_app" {
  name = "devops-nodejs-app"
  build {
    context = "../../"
    dockerfile = "Dockerfile"
  }
}

# NodeJS Application Container
resource "docker_container" "nodejs_app" {
  image = docker_image.nodejs_app.name
  name  = "devops-nodejs-app"

  networks_advanced {
    name = docker_network.devops_network.name
  }

  env = [
    "DB_HOST=devops-postgres",
    "DB_USER=admin",
    "DB_PASSWORD=admin",
    "DB_NAME=devops_class",
    "DB_PORT=5432"
  ]

  ports {
    internal = 3000
    external = 3000
  }

  depends_on = [docker_container.postgres]
}