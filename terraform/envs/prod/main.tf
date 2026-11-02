provider "aws" {
  region = var.regiao
}

data "aws_availability_zones" "disponiveis" {
  state = "available"
}

module "rede" {
  source         = "../../modulos/rede"
  nome           = var.nome
  zonas          = slice(data.aws_availability_zones.disponiveis.names, 0, 2)
  cidrs_publicas = ["10.0.0.0/24", "10.0.1.0/24"]
  cidrs_privadas = ["10.0.10.0/24", "10.0.11.0/24"]
  nat_gateway    = var.nat_gateway
}
