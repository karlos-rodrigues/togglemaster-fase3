variable "prefixo" { type = string }
variable "urls_bancos" {
  type      = map(string)
  sensitive = true
}
variable "redis_url" { type = string }
variable "sqs_url" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
