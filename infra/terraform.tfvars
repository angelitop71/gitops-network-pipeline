# =================================================================
#  ESTE ES EL ARCHIVO QUE SE EDITA EN LA DEMO.
#  Cualquier cambio aqui -> Pull Request -> plan -> merge -> deploy
# =================================================================

project = "gitops-net"

# Topologia: DMZ expuesta + backend aislado
networks = {
  dmz = {
    subnet   = "172.30.10.0/24"
    internal = false
  }
  backend = {
    subnet   = "172.30.20.0/24"
    internal = true # sin salida a Internet; la DB vive solo aqui
  }
}

web_count = 2

# Reglas de seguridad de entrada (Docker publica el puerto + iptables lo permite)
firewall_rules = {
  http = {
    port      = 80
    host_port = 8001 # web-1 -> localhost:8001, web-2 -> localhost:8002
    source    = "0.0.0.0/0"
  }
  # DEMO: descomentar en un Pull Request para abrir un nuevo servicio
  #  app = {
  #   port      = 8080
  #  host_port = 9001 # web-1 -> localhost:9001, web-2 -> localhost:9002
  #  source    = "0.0.0.0/0"
  }
}
