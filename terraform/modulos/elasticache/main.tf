resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.nome}-cache"
  subnet_ids = var.subnets
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.nome}-cache"
  description = "Redis somente a partir do cluster EKS"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "redis" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.sg_origem_id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

resource "aws_elasticache_cluster" "this" {
  cluster_id         = "${var.nome}-evaluation-cache"
  engine             = "redis"
  engine_version     = var.versao_engine
  node_type          = var.classe
  num_cache_nodes    = 1
  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]
  tags               = var.tags
}
