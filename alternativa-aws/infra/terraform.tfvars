# =================================================================
#  ESTE ES EL ARCHIVO QUE SE EDITA EN LA DEMO.
#  Cualquier cambio aqui -> Pull Request -> plan -> merge -> deploy
# =================================================================

project  = "gitops-net"
region   = "us-east-1"
vpc_cidr = "10.10.0.0/16"

# Topologia: una subred por zona de disponibilidad
subnets = {
  "publica-a" = { cidr = "10.10.1.0/24", az = "us-east-1a" }
  "publica-b" = { cidr = "10.10.2.0/24", az = "us-east-1b" }
}

web_count     = 2
instance_type = "t3.micro"

# Reglas de seguridad (firewall de red)
web_ingress_rules = {
  ssh = {
    port        = 22
    cidr        = "0.0.0.0/0" # solo llave SSH; ver "limitaciones" en el informe
    description = "SSH para Ansible"
  }
  http = {
    port        = 80
    cidr        = "0.0.0.0/0"
    description = "HTTP publico"
  }
  # DEMO: descomentar en un PR para abrir un nuevo servicio
  # app = {
  #   port        = 8080
  #   cidr        = "0.0.0.0/0"
  #   description = "App interna"
  # }
}
