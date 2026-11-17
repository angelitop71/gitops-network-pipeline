output "web_public_ips" {
  description = "IPs publicas de los servidores web"
  value       = aws_instance.web[*].public_ip
}

output "ansible_inventory" {
  description = "Inventario de Ansible generado desde el estado de OpenTofu"
  value = templatefile("${path.module}/templates/inventory.tftpl", {
    web = aws_instance.web
  })
}

output "open_ports" {
  description = "Puertos abiertos en el Security Group (Ansible los replica en UFW)"
  value       = sort(distinct([for r in var.web_ingress_rules : r.port]))
}
