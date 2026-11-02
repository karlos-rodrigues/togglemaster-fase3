output "nome" { value = aws_eks_cluster.this.name }
output "endpoint" { value = aws_eks_cluster.this.endpoint }
output "sg_cluster_id" { value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id }
output "oidc_arn" { value = aws_iam_openid_connect_provider.this.arn }
output "oidc_url" { value = aws_iam_openid_connect_provider.this.url }
output "role_nos_arn" { value = aws_iam_role.nos.arn }
