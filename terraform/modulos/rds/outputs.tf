output "enderecos" {
  value = { for k, v in aws_db_instance.this : k => v.address }
}

output "segredos_arn" {
  value = { for k, v in aws_db_instance.this : k => v.master_user_secret[0].secret_arn }
}
