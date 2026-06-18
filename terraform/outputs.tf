output "jenkins_url" {
  value       = var.jenkins_enabled ? "http://localhost:8082" : "Jenkins desabilitado"
  description = "URL de acesso ao Jenkins"
}

output "homologacao_url" {
  value       = var.homologacao_enabled ? "http://localhost:3002" : "Homologação não criada"
  description = "URL de acesso à Homologação"
}

output "producao_url" {
  value       = var.producao_enabled ? "http://localhost:3000" : "Produção não criada"
  description = "URL de acesso à Produção"
}
