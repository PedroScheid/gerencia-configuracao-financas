variable "jenkins_enabled" {
  description = "Habilita o container do Jenkins"
  type        = bool
  default     = true
}

variable "homologacao_enabled" {
  description = "Habilita o container de Homologação"
  type        = bool
  default     = false
}

variable "producao_enabled" {
  description = "Habilita o container de Produção"
  type        = bool
  default     = false
}
