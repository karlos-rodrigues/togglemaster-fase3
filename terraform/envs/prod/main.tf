provider "aws" {
  region = var.regiao
}

data "aws_availability_zones" "disponiveis" {
  state = "available"
}

locals {
  tags = { Projeto = "togglemaster", Fase = "3", GerenciadoPor = "terraform" }
}

module "rede" {
  source         = "../../modulos/rede"
  nome           = var.nome
  zonas          = slice(data.aws_availability_zones.disponiveis.names, 0, 2)
  cidrs_publicas = ["10.0.0.0/24", "10.0.1.0/24"]
  cidrs_privadas = ["10.0.10.0/24", "10.0.11.0/24"]
  nat_gateway    = var.nat_gateway
  tags           = local.tags
}

module "eks" {
  source           = "../../modulos/eks"
  nome             = var.nome
  versao_k8s       = var.versao_k8s
  vpc_id           = module.rede.vpc_id
  subnets_cluster  = concat(module.rede.subnets_publicas, module.rede.subnets_privadas)
  cidrs_acesso_api = var.cidrs_acesso_api
  subnets_nos      = var.nat_gateway ? module.rede.subnets_privadas : module.rede.subnets_publicas
  tags             = local.tags
}

module "rds" {
  source       = "../../modulos/rds"
  nome         = var.nome
  vpc_id       = module.rede.vpc_id
  subnets      = module.rede.subnets_privadas
  sg_origem_id = module.eks.sg_cluster_id
  bancos = {
    auth      = "auth_db"
    flag      = "flag_db"
    targeting = "targeting_db"
  }
  tags = local.tags
}

module "elasticache" {
  source       = "../../modulos/elasticache"
  nome         = var.nome
  vpc_id       = module.rede.vpc_id
  subnets      = module.rede.subnets_privadas
  sg_origem_id = module.eks.sg_cluster_id
  tags         = local.tags
}

module "dynamodb" {
  source = "../../modulos/dynamodb"
  tags   = local.tags
}

module "sqs" {
  source = "../../modulos/sqs"
  nome   = "${var.nome}-evaluation-events"
  tags   = local.tags
}

module "ecr" {
  source       = "../../modulos/ecr"
  repositorios = var.servicos
  tags         = local.tags
}

data "aws_iam_policy_document" "evaluation" {
  statement {
    actions   = ["sqs:SendMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
    resources = [module.sqs.arn]
  }
}

data "aws_iam_policy_document" "analytics" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
    resources = [module.sqs.arn]
  }
  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:DescribeTable"]
    resources = [module.dynamodb.arn]
  }
}

module "irsa_evaluation" {
  source          = "../../modulos/irsa"
  nome            = "${var.nome}-evaluation-irsa"
  oidc_arn        = module.eks.oidc_arn
  oidc_url        = module.eks.oidc_url
  namespace       = "evaluation"
  service_account = "evaluation-sa"
  politica_json   = data.aws_iam_policy_document.evaluation.json
  tags            = local.tags
}

module "irsa_analytics" {
  source          = "../../modulos/irsa"
  nome            = "${var.nome}-analytics-irsa"
  oidc_arn        = module.eks.oidc_arn
  oidc_url        = module.eks.oidc_url
  namespace       = "analytics"
  service_account = "analytics-sa"
  politica_json   = data.aws_iam_policy_document.analytics.json
  tags            = local.tags
}
