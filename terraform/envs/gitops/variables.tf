variable "regiao" {
  type    = string
  default = "us-east-1"
}

variable "nome" {
  type    = string
  default = "togglemaster"
}

variable "repo_gitops" {
  type    = string
  default = "git@github.com:karlos-rodrigues/togglemaster-gitops.git"
}

variable "ssh_private_key" {
  description = "Deploy key somente leitura do repositório GitOps; definida em terraform.tfvars, fora do Git"
  type        = string
  sensitive   = true
}
