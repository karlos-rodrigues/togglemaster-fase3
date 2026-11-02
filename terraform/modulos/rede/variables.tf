variable "nome" {
  description = "Prefixo dos recursos e nome do cluster EKS que usará a rede"
  type        = string
}

variable "cidr_vpc" {
  type    = string
  default = "10.0.0.0/16"
}

variable "zonas" {
  description = "Zonas de disponibilidade (mínimo 2, exigência do EKS e do RDS)"
  type        = list(string)
}

variable "cidrs_publicas" {
  type = list(string)
}

variable "cidrs_privadas" {
  type = list(string)
}

variable "nat_gateway" {
  description = "Cria um NAT Gateway (custo por hora e por GB) para as sub-redes privadas saírem para a internet"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
