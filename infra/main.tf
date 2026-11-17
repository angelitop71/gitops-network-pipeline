# ---------------------------------------------------------------
# Topologia de red (segmentacion)
#   dmz     : red expuesta, con salida a Internet
#   backend : red interna aislada (internal = true), solo servidores
# ---------------------------------------------------------------
resource "docker_network" "net" {
  for_each = var.networks

  name     = "${var.project}-${each.key}"
  driver   = "bridge"
  internal = each.value.internal

  ipam_config {
    subnet = each.value.subnet
  }

  labels {
    label = "managed-by"
    value = "opentofu-gitops"
  }
}

# ---------------------------------------------------------------
# Imagenes
# ---------------------------------------------------------------
resource "docker_image" "base" {
  name         = var.base_image
  keep_locally = true
}

resource "docker_image" "db" {
  name         = "redis:7-alpine"
  keep_locally = true
}

# ---------------------------------------------------------------
# Base de datos: SOLO en la red backend, sin puertos publicados
# => inalcanzable desde el host / Internet
# ---------------------------------------------------------------
resource "docker_container" "db" {
  name     = "${var.project}-db"
  hostname = "db"
  image    = docker_image.db.image_id
  restart  = "unless-stopped"

  networks_advanced {
    name    = docker_network.net["backend"].name
    aliases = ["db"]
  }
}

# ---------------------------------------------------------------
# Servidores web: en dmz + backend. Los puertos publicados salen
# de var.firewall_rules (la misma fuente que usa iptables).
# ---------------------------------------------------------------
resource "docker_container" "web" {
  count = var.web_count

  name     = "${var.project}-web-${count.index + 1}"
  hostname = "web-${count.index + 1}"
  image    = docker_image.base.image_id
  command  = ["sleep", "infinity"] # Ansible instala y levanta los servicios
  restart  = "unless-stopped"

  capabilities {
    add = ["NET_ADMIN"] # necesario para que Ansible configure iptables
  }

  networks_advanced {
    name = docker_network.net["dmz"].name
  }

  networks_advanced {
    name = docker_network.net["backend"].name
  }

  dynamic "ports" {
    for_each = var.firewall_rules
    content {
      internal = ports.value.port
      external = ports.value.host_port + count.index
    }
  }

  labels {
    label = "role"
    value = "web"
  }
}
