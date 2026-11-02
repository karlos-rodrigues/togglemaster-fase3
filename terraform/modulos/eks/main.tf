data "aws_iam_policy_document" "assume_eks" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_nos" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.nome}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.assume_eks.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = var.nome
  version  = var.versao_k8s
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnets_cluster
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags       = var.tags
  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_iam_role" "nos" {
  name               = "${var.nome}-eks-nos"
  assume_role_policy = data.aws_iam_policy_document.assume_nos.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "nos" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  role       = aws_iam_role.nos.name
  policy_arn = each.value
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.nome}-nodes"
  node_role_arn   = aws_iam_role.nos.arn
  subnet_ids      = var.subnets_nos
  instance_types  = [var.tipo_instancia]

  scaling_config {
    min_size     = var.nos_min
    desired_size = var.nos_desejado
    max_size     = var.nos_max
  }

  tags       = var.tags
  depends_on = [aws_iam_role_policy_attachment.nos]
}

resource "aws_iam_openid_connect_provider" "this" {
  url            = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}
