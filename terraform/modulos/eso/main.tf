data "aws_iam_policy_document" "ler" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.segredos_arns
  }
}

module "irsa" {
  source          = "../irsa"
  nome            = var.nome
  oidc_arn        = var.oidc_arn
  oidc_url        = var.oidc_url
  namespace       = "external-secrets"
  service_account = "external-secrets"
  politica_json   = data.aws_iam_policy_document.ler.json
  tags            = var.tags
}
