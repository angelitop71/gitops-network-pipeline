terraform {
  required_version = ">= 1.8.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # Backend local: el estado (infra/terraform.tfstate) se versiona en el
  # repositorio; el pipeline lo commitea despues de cada apply/destroy.
}

# Se conecta al Docker del servidor donde corre el runner (unix socket)
provider "docker" {}
