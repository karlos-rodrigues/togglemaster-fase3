resource "aws_db_subnet_group" "this" {
  name       = "${var.nome}-rds"
  subnet_ids = var.subnets
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.nome}-rds"
  description = "PostgreSQL somente a partir do cluster EKS"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.sg_origem_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_db_instance" "this" {
  for_each = var.bancos

  identifier                          = "${var.nome}-${each.key}"
  engine                              = "postgres"
  engine_version                      = var.versao_engine
  instance_class                      = var.classe
  allocated_storage                   = var.armazenamento_gb
  storage_encrypted                   = true
  db_name                             = each.value
  username                            = "togglemaster"
  manage_master_user_password         = true
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.this.id]
  publicly_accessible                 = false
  multi_az                            = false
  skip_final_snapshot                 = true
  backup_retention_period             = 7
  iam_database_authentication_enabled = true
  deletion_protection                 = false
  tags                                = merge(var.tags, { Servico = each.key })
}
