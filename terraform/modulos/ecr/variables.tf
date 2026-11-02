variable "repositorios" { type = list(string) }
variable "tags" {
  type    = map(string)
  default = {}
}
