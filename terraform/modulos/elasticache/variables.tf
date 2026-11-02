variable "nome" { type = string }
variable "vpc_id" { type = string }
variable "subnets" { type = list(string) }
variable "sg_origem_id" { type = string }
variable "classe" {
  type    = string
  default = "cache.t3.micro"
}
variable "versao_engine" {
  type    = string
  default = "7.1"
}
variable "tags" {
  type    = map(string)
  default = {}
}
