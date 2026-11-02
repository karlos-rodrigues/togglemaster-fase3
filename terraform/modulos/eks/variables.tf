variable "nome" { type = string }
variable "versao_k8s" { type = string }
variable "vpc_id" { type = string }
variable "subnets_cluster" { type = list(string) }
variable "subnets_nos" { type = list(string) }
variable "tipo_instancia" {
  type    = string
  default = "t3.medium"
}
variable "nos_min" {
  type    = number
  default = 1
}
variable "nos_desejado" {
  type    = number
  default = 2
}
variable "nos_max" {
  type    = number
  default = 4
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "cidrs_acesso_api" {
  description = "CIDRs autorizados a acessar o endpoint público da API do cluster"
  type        = list(string)
}
