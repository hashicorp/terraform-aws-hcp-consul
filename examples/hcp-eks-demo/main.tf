data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name                 = "${var.cluster_id}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

data "aws_eks_cluster" "cluster2" {
  name = module.eks-2.cluster_id
}

data "aws_eks_cluster_auth" "cluster2" {
  name = module.eks-2.cluster_id
}

module "eks-2" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.22.0"

  cluster_name    = "hcp-${var.cluster_id}-2"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets
  manage_aws_auth = false
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    application = {
      instance_types   = ["t3a.medium"]
      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 3
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.22.0"

  cluster_name    = "hcp-${var.cluster_id}"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  manage_aws_auth = false

  node_groups = {
    application = {
      instance_types   = ["t3a.medium"]
      desired_capacity = 3
      max_capacity     = 3
      min_capacity     = 3
    }
  }
}

# The HVN created in HCP
data "hcp_hvn" "main" {
  hvn_id = "hvn-dev"
}
# resource "hcp_hvn" "main" {
#   hvn_id         = var.hvn_id
#   cloud_provider = "aws"
#   region         = var.region
#   cidr_block     = var.hvn_cidr_block
# }

module "aws_hcp_consul" {
  source = "hashicorp/hcp-consul/aws"

  hvn                = data.hcp_hvn.main
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  route_table_ids    = module.vpc.private_route_table_ids
  security_group_ids = [module.eks.cluster_primary_security_group_id, module.eks-2.cluster_primary_security_group_id]
}

data "hcp_consul_cluster" "main" {
  cluster_id = "consul-admin-partitions"
}
# resource "hcp_consul_cluster" "main" {
#   cluster_id      = var.cluster_id
#   hvn_id          = hcp_hvn.main.hvn_id
#   public_endpoint = !var.disable_public_url
#   size            = var.size
#   tier            = var.tier
#   min_consul_version = "v1.11.0-rc"
# }

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = data.hcp_consul_cluster.main.id
}

module "eks_consul_client" {
  source = "../../modules/hcp-eks-client"

  cluster_id       = "adminpartition1"
  consul_hosts     = jsondecode(base64decode(data.hcp_consul_cluster.main.consul_config_file))["retry_join"]
  k8s_api_endpoint = module.eks.cluster_endpoint

  boostrap_acl_token    = hcp_consul_cluster_root_token.token.secret_id
  consul_ca_file        = base64decode(data.hcp_consul_cluster.main.consul_ca_file)
  datacenter            = data.hcp_consul_cluster.main.datacenter
  gossip_encryption_key = jsondecode(base64decode(data.hcp_consul_cluster.main.consul_config_file))["encrypt"]

  # The EKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [module.eks]
}

module "eks_consul_client-2" {
  source = "../../modules/hcp-eks-client"
  providers = {
    helm       = helm.eks-2
    kubernetes = kubernetes.eks-2
  }

  cluster_id       = "adminpartition2"
  consul_hosts     = jsondecode(base64decode(data.hcp_consul_cluster.main.consul_config_file))["retry_join"]
  k8s_api_endpoint = module.eks-2.cluster_endpoint

  boostrap_acl_token    = hcp_consul_cluster_root_token.token.secret_id
  consul_ca_file        = base64decode(data.hcp_consul_cluster.main.consul_ca_file)
  datacenter            = data.hcp_consul_cluster.main.datacenter
  gossip_encryption_key = jsondecode(base64decode(data.hcp_consul_cluster.main.consul_config_file))["encrypt"]

  # The EKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [module.eks-2]
}

module "demo_app" {
  source     = "../../modules/k8s-demo-app"
  prefix     = "consul-adminpartition1"
  depends_on = [module.eks_consul_client]
}
