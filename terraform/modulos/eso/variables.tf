variable "nome" { type = string }
variable "oidc_arn" { type = string }
variable "oidc_url" { type = string }
variable "segredos_arns" { type = list(string) }
variable "tags" {
  type    = map(string)
  default = {}
}
