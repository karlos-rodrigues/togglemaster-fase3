output "vpc_id" {
  value = module.rede.vpc_id
}

output "subnets_publicas" {
  value = module.rede.subnets_publicas
}

output "subnets_privadas" {
  value = module.rede.subnets_privadas
}
