# Jenkins e Zabbix rodam de forma permanente, fora deste Terraform.
output "jenkins_url" {
  value       = "http://localhost:8082"
  description = "URL de acesso ao Jenkins (infra permanente)"
}

output "zabbix_url" {
  value       = "http://localhost:8080"
  description = "URL de acesso ao Zabbix (infra permanente)"
}

output "homologacao_url" {
  value       = var.homologacao_enabled ? "http://localhost:3002" : "Homologação não criada"
  description = "URL de acesso à Homologação"
}

output "producao_url" {
  value       = var.producao_enabled ? "http://localhost:3000" : "Produção não criada"
  description = "URL de acesso à Produção"
}
