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

variable "cidrs_acesso_api" {
  description = "CIDRs autorizados na API do EKS (IP público da forge /32); definido em terraform.tfvars, fora do Git"
  type        = list(string)
}

variable "repositorios_github" {
  description = "ID numérico de cada repositório de serviço (necessário para o subject imutável do OIDC do GitHub)"
  type        = map(string)
  default = {
    auth-service       = "1428824411"
    flag-service       = "1428824626"
    targeting-service  = "1428824736"
    evaluation-service = "1428824528"
    analytics-service  = "1428824303"
  }
}

variable "dono_github_id" {
  type    = string
  default = "323592744"
}
