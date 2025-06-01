terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_image" "mongo" {
  name = "mongo:latest"
}

resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}

resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
}

resource "docker_image" "app" {
  name = "order-service-app"
  build {
    context = "${path.module}/../app"
  }
}

resource "docker_container" "mongo" {
  name  = "mongo"
  image = docker_image.mongo.name
  ports {
    internal = 27017
    external = 27017
  }
  must_run = true
  rm       = true  # Контейнер удаляется после остановки
}

resource "docker_container" "app" {
  name  = "nodejs-app"
  image = docker_image.app.name
  depends_on = [docker_container.mongo]
  ports {
    internal = 3000
    external = 3000
  }
  env = ["MONGO_URL=mongodb://mongo:27017/tasks"]
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.name
  ports {
    internal = 9090
    external = 9090
  }
  must_run = true
  rm       = true

  volumes {
    host_path      = abspath("${path.module}/../prometheus.yml")  # Абсолютный путь!
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.name
  ports {
    internal = 3000
    external = 3001
  }
  must_run = true
  rm       = true
}
