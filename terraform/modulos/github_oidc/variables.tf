variable "nome" { type = string }
variable "dono_github" { type = string }
variable "dono_id" { type = string }
variable "repositorios" {
  description = "Mapa nome do repositório => ID numérico (a conta usa subject imutável no OIDC)"
  type        = map(string)
}
variable "ecr_arns" { type = list(string) }
variable "tags" {
  type    = map(string)
  default = {}
}
