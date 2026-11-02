provider "aws" {
  region = var.regiao
}

data "aws_caller_identity" "atual" {}

data "aws_eks_cluster" "this" {
  name = var.nome
}

data "aws_eks_cluster_auth" "this" {
  name = var.nome
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "2.14.0"
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "arn:aws:iam::${data.aws_caller_identity.atual.account_id}:role/${var.nome}-external-secrets"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.11.6"
  namespace        = "argocd"
  create_namespace = true

  values = [yamlencode({
    configs = {
      repositories = {
        gitops = {
          name          = "togglemaster-gitops"
          type          = "git"
          url           = var.repo_gitops
          sshPrivateKey = var.ssh_private_key
        }
      }
    }
  })]
}

resource "helm_release" "raiz" {
  name       = "togglemaster-raiz"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.7"
  namespace  = "argocd"
  depends_on = [helm_release.argocd, helm_release.external_secrets]

  values = [yamlencode({
    applications = {
      raiz = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = var.repo_gitops
          targetRevision = "main"
          path           = "argocd"
          directory      = { recurse = false }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = { prune = true, selfHeal = true }
        }
      }
    }
  })]
}
