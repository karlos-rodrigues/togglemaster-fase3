resource "aws_sqs_queue" "this" {
  name                       = var.nome
  visibility_timeout_seconds = 60
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true
  tags                       = var.tags
}
