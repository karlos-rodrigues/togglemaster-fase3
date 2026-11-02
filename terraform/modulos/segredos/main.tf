resource "random_password" "master_key" {
  length  = 48
  special = false
}

locals {
  conteudo = {
    auth       = { DATABASE_URL = var.urls_bancos["auth"], MASTER_KEY = random_password.master_key.result }
    flag       = { DATABASE_URL = var.urls_bancos["flag"] }
    targeting  = { DATABASE_URL = var.urls_bancos["targeting"] }
    evaluation = { REDIS_URL = var.redis_url, AWS_SQS_URL = var.sqs_url, SERVICE_API_KEY = "definir-apos-bootstrap" }
    analytics  = { AWS_SQS_URL = var.sqs_url }
  }
}

resource "aws_secretsmanager_secret" "this" {
  for_each                = local.conteudo
  name                    = "${var.prefixo}/${each.key}"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each      = local.conteudo
  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = jsonencode(each.value)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
