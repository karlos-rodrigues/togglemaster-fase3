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
  default = "https://github.com/karlos-rodrigues/togglemaster-gitops.git"
}
