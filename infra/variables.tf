variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
}

variable "networks" {
  description = "Segmentos de red. Deben existir 'dmz' y 'backend'. internal = true => sin salida a Internet"
  type = map(object({
    subnet   = string
    internal = bool
  }))

  validation {
    condition     = contains(keys(var.networks), "dmz") && contains(keys(var.networks), "backend")
    error_message = "Se requieren las redes 'dmz' y 'backend'."
  }
}

variable "web_count" {
  description = "Cantidad de servidores web"
  type        = number
  default     = 2
}

variable "firewall_rules" {
  description = <<-EOT
    Reglas de seguridad de entrada para los servidores web.
    port      = puerto del servicio dentro del servidor (iptables lo permite)
    host_port = puerto publicado en el host para web-1 (web-2 usa host_port+1, etc.)
    source    = red de origen permitida (CIDR)
  EOT
  type = map(object({
    port      = number
    host_port = number
    source    = string
  }))
}

variable "base_image" {
  description = "Imagen base de los servidores web (Debian minimo; Ansible instala el resto)"
  type        = string
  default     = "debian:bookworm-slim"
}
