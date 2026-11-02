terraform {
  backend "s3" {
    key          = "togglemaster/fase3/prod/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
