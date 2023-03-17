locals {
  vpc_region          = "{{ .VPCRegion }}"
  hvn_region          = "{{ .HVNRegion }}"
  cluster_id          = "{{ .ClusterID }}"
  hvn_id              = "{{ .ClusterID }}-hvn"
  install_demo_app    = true
  vpc_id              = "{{ .VPCID }}"
  private_subnet1     = "{{ .PrivateSubnet1 }}"
  private_subnet2     = "{{ .PrivateSubnet2 }}"
  install_eks_cluster = true
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47"
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

}

provider "aws" {
  region = local.vpc_region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = true
}

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks.cluster_arn]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks.cluster_arn]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name                   = "${local.cluster_id}-eks"
  subnet_ids                     = [local.private_subnet1, local.private_subnet2]
  vpc_id                         = local.vpc_id
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    application = {
      name_prefix    = "hashicups"
      instance_types = ["t3a.medium"]

      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 3
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.16.1-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }

  depends_on = [module.eks]
}

# The HVN created in HCP
resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id
  cloud_provider = "aws"
  region         = local.hvn_region
  cidr_block     = "172.25.32.0/20"
}

# Note: Uncomment the below module to setup peering for connecting to a private HCP Consul cluster
# module "aws_hcp_consul" {
#   source  = "hashicorp/hcp-consul/aws"
#   version = "~> 0.10.0"
#
#   hvn                = hcp_hvn.main
#   vpc_id             = local.vpc_id
#   subnet_ids         = [local.private_subnet1, local.private_subnet2]
#   route_table_ids    = [local.private_route_table_id]
#   security_group_ids = local.install_eks_cluster ? [module.eks[0].cluster_primary_security_group_id] : [""]
# }

resource "hcp_consul_cluster" "main" {
  cluster_id         = local.cluster_id
  hvn_id             = hcp_hvn.main.hvn_id
  public_endpoint    = true
  tier               = "development"
  min_consul_version = "v1.14.0"
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

module "eks_consul_client" {
  source  = "hashicorp/hcp-consul/aws//modules/hcp-eks-client"
  version = "~> 0.10.0"

  boostrap_acl_token = hcp_consul_cluster_root_token.token.secret_id
  cluster_id         = hcp_consul_cluster.main.cluster_id
  # strip out url scheme from the public url
  consul_hosts     = tolist([substr(hcp_consul_cluster.main.consul_public_endpoint_url, 8, -1)])
  consul_version   = hcp_consul_cluster.main.consul_version
  datacenter       = hcp_consul_cluster.main.datacenter
  k8s_api_endpoint = module.eks.cluster_endpoint

  # The EKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [module.eks, aws_eks_addon.ebs-csi]
}

module "demo_app" {
  count   = local.install_demo_app ? 1 : 0
  source  = "hashicorp/hcp-consul/aws//modules/k8s-demo-app"
  version = "~> 0.10.0"

  depends_on = [module.eks_consul_client]
}
output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "consul_url" {
  value = hcp_consul_cluster.main.public_endpoint ? (
    hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

output "helm_values_filename" {
  value = abspath(module.eks_consul_client.helm_values_file)
}

output "hashicups_url" {
  value = "${one(module.demo_app[*].hashicups_url)}:8080"
}

output "next_steps" {
  value = "HashiCups Application will be ready in ~2 minutes. Use 'terraform output -raw consul_root_token' to retrieve the root token."
}

output "howto_connect" {
  value = <<EOF
  ${local.install_demo_app ? "The demo app, HashiCups, Has been installed for you and its components registered in Consul." : ""}
  ${local.install_demo_app ? "To access HashiCups navigate to: ${one(module.demo_app[*].hashicups_url)}:8080" : ""}

  To access Consul from your local client run:

      export CONSUL_HTTP_ADDR="${hcp_consul_cluster.main.consul_public_endpoint_url}"
      export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token)
  
  ${local.install_eks_cluster ? "You can access your provisioned eks cluster by first running following command" : ""}

      ${local.install_eks_cluster ? "aws eks update-kubeconfig --region ${local.vpc_region} --name  ${module.eks.cluster_name}" : ""}

  Consul has been installed in the default namespace. To explore what has been installed run:
  
  kubectl get pods

  EOF
}
