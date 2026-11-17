variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
}

variable "subnets" {
  description = "Subredes publicas de la topologia (nombre => cidr + zona)"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "web_count" {
  description = "Cantidad de servidores web"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "web_ingress_rules" {
  description = "Reglas de entrada del Security Group web (nombre => puerto + origen)"
  type = map(object({
    port        = number
    protocol    = optional(string, "tcp")
    cidr        = string
    description = string
  }))
}

variable "ssh_public_key" {
  description = "Llave publica SSH que usara Ansible (viene de un secret de GitHub)"
  type        = string
}
