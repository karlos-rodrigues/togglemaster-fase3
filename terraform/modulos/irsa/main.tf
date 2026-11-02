locals {
  issuer = replace(var.oidc_url, "https://", "")
}

data "aws_iam_policy_document" "confianca" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.issuer}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.nome
  assume_role_policy = data.aws_iam_policy_document.confianca.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "this" {
  name   = var.nome
  role   = aws_iam_role.this.id
  policy = var.politica_json
}
