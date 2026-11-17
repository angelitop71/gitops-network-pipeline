output "ansible_inventory" {
  description = "Inventario de Ansible generado desde el estado de OpenTofu"
  value = templatefile("${path.module}/templates/inventory.tftpl", {
    web = docker_container.web[*].name
  })
}

output "firewall_rules" {
  description = "Reglas que Ansible aplica en iptables"
  value       = [for k, r in var.firewall_rules : { name = k, port = r.port, source = r.source }]
}

output "web_urls" {
  description = "URLs publicadas en el host"
  value = flatten([
    for i in range(var.web_count) : [
      for k, r in var.firewall_rules : "http://localhost:${r.host_port + i}"
    ]
  ])
}

output "topologia" {
  description = "Resumen de la red desplegada"
  value = {
    for k, n in docker_network.net : k => {
      subnet   = var.networks[k].subnet
      internal = n.internal
    }
  }
}
