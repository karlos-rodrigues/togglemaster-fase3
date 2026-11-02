variable "nome" { type = string }
variable "dono_github" { type = string }
variable "repositorios" { type = list(string) }
variable "ecr_arns" { type = list(string) }
variable "tags" {
  type    = map(string)
  default = {}
}
