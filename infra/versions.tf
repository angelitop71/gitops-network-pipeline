terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend local: el estado (infra/terraform.tfstate) se versiona en el
  # propio repositorio y el pipeline lo commitea despues de cada apply.
  # (La cuenta AWS del curso bloquea S3 mediante una SCP de la organizacion.)
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "OpenTofu-GitOps"
    }
  }
}
