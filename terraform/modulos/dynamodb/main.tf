resource "aws_dynamodb_table" "this" {
  name         = var.nome
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = var.tags
}
