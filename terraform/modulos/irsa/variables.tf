variable "nome" { type = string }
variable "oidc_arn" { type = string }
variable "oidc_url" { type = string }
variable "namespace" { type = string }
variable "service_account" { type = string }
variable "politica_json" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
