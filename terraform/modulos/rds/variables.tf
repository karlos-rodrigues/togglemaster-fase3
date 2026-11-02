variable "nome" { type = string }
variable "vpc_id" { type = string }
variable "subnets" { type = list(string) }
variable "sg_origem_id" { type = string }
variable "bancos" {
  description = "Mapa serviço => nome do banco lógico"
  type        = map(string)
}
variable "versao_engine" {
  type    = string
  default = "17"
}
variable "classe" {
  type    = string
  default = "db.t3.micro"
}
variable "armazenamento_gb" {
  type    = number
  default = 20
}
variable "tags" {
  type    = map(string)
  default = {}
}
