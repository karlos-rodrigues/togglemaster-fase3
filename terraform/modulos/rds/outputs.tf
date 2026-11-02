output "enderecos" {
  value = { for k, v in aws_db_instance.this : k => v.address }
}

output "urls" {
  sensitive = true
  value = {
    for k, v in aws_db_instance.this : k => "postgres://${v.username}:${random_password.this[k].result}@${v.address}:5432/${v.db_name}"
  }
}
