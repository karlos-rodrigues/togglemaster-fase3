output "arns" {
  value = [for s in aws_secretsmanager_secret.this : s.arn]
}
