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
  private_subnets      = []
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  enable_dns_hostnames = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "hcp-${var.cluster_id}"
  cluster_version = "1.21"
  subnets         = module.vpc.public_subnets
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

# The HVN created in HCP
resource "hcp_hvn" "main" {
  hvn_id         = var.hvn_id
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = var.hvn_cidr_block
}

module "aws_hcp_consul" {
  source = "hashicorp/hcp-consul/aws"

  hvn                = hcp_hvn.main
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnets
  route_table_ids    = module.vpc.public_route_table_ids
  security_group_ids = [module.eks.cluster_primary_security_group_id]
}

resource "hcp_consul_cluster" "main" {
  cluster_id      = var.cluster_id
  hvn_id          = hcp_hvn.main.hvn_id
  public_endpoint = !var.disable_public_url
  size            = var.size
  tier            = var.tier
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.cluster_id
}

module "eks_consul_client" {
  source = "hashicorp/hcp-consul/aws//modules/hcp-eks-client"

  cluster_id       = hcp_consul_cluster.main.cluster_id
  consul_hosts     = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  k8s_api_endpoint = module.eks.cluster_endpoint

  boostrap_acl_token    = hcp_consul_cluster_root_token.token.secret_id
  consul_ca_file        = base64decode(hcp_consul_cluster.main.consul_ca_file)
  datacenter            = hcp_consul_cluster.main.datacenter
  gossip_encryption_key = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]

  # The EKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [module.eks]
}

module "demo_app" {
  source     = "hashicorp/hcp-consul/aws//modules/k8s-demo-app"
  depends_on = [module.eks_consul_client]
}
