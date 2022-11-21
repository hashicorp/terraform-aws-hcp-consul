terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.18.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.14.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.7.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }

  provider_meta "hcp" {
    module_name = "hcp-consul"
  }
}

provider "aws" {
  region = var.vpc_region
}

provider "helm" {
  kubernetes {
    host                   = var.install_eks_cluster ? data.aws_eks_cluster.cluster[0].endpoint : ""
    cluster_ca_certificate = var.install_eks_cluster ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : ""
    token                  = var.install_eks_cluster ? data.aws_eks_cluster_auth.cluster[0].token : ""
  }
}

provider "kubernetes" {
  host                   = var.install_eks_cluster ? data.aws_eks_cluster.cluster[0].endpoint : ""
  cluster_ca_certificate = var.install_eks_cluster ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : ""
  token                  = var.install_eks_cluster ? data.aws_eks_cluster_auth.cluster[0].token : ""
}

provider "kubectl" {
  host                   = var.install_eks_cluster ? data.aws_eks_cluster.cluster[0].endpoint : ""
  cluster_ca_certificate = var.install_eks_cluster ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : ""
  token                  = var.install_eks_cluster ? data.aws_eks_cluster_auth.cluster[0].token : ""
  load_config_file       = false
}
