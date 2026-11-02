terraform {
  backend "s3" {
    key          = "togglemaster/fase3/gitops/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
