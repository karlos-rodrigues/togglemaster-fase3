variable "regiao" {
  type    = string
  default = "us-east-1"
}

variable "nome" {
  type    = string
  default = "togglemaster"
}

variable "versao_k8s" {
  type    = string
  default = "1.36"
}

variable "nat_gateway" {
  type    = bool
  default = true
}

variable "servicos" {
  type    = list(string)
  default = ["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"]
}
