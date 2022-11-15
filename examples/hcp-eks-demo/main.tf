data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name                 = "${var.cluster_id}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

data "aws_eks_cluster" "cluster" {
  count = var.install_eks_cluster ? 1 : 0
  name  = module.eks[0].cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.install_eks_cluster ? 1 : 0
  name  = module.eks[0].cluster_id
}

module "eks" {
  count                  = var.install_eks_cluster ? 1 : 0
  source                 = "terraform-aws-modules/eks/aws"
  version                = "18.30.3"

  cluster_name    = "chappie-fargate-eks2"
  cluster_version = "1.21"
  subnet_ids        = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_security_group_additional_rules = {
    ingress_all = {
      description      = "Node all ingress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
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
  create_cluster_primary_security_group_tags = false

  cluster_security_group_additional_rules = {
    ingress_all = {
      description      = "Node all ingress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
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

  eks_managed_node_groups = {
    application = {
      name_prefix      = "hcp-eks-demo"
      instance_types   = ["t3a.medium"]

      desired_size = var.fargate_eks ? 2 : 3
      max_size     = var.fargate_eks ? 2 : 3
      min_size     = var.fargate_eks ? 2 : 3
    }
  }

  fargate_profiles = var.fargate_eks ? {
    default = {
      name      = "default"
      selectors = [
        {
          namespace = "consul"
        },
        {
          namespace = "default"
        }
      ]
    }
  } : {}

}

resource "aws_security_group_rule" "cluster" {
  count = var.fargate_eks ? 1 : 0
  security_group_id = module.eks[0].cluster_primary_security_group_id
  protocol         = "tcp"
  from_port        = 8080
  to_port          = 8080
  type             = "ingress"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

# The HVN created in HCP
# resource "hcp_hvn" "main" {
#   hvn_id         = var.hvn_id
#   cloud_provider = "aws"
#   region         = var.hvn_region
#   cidr_block     = var.hvn_cidr_block
# }

data "hcp_hvn" "example" {
  hvn_id = "eks2"
}

# Note: Uncomment the below module to setup peering for connecting to a private HCP Consul cluster
# module "aws_hcp_consul" {
#   source  = "hashicorp/hcp-consul/aws"
#   version = "~> 0.8.9"
#   hvn                = hcp_hvn.main
#   vpc_id             = module.vpc.vpc_id
#   subnet_ids         = module.vpc.private_subnets
#   route_table_ids    = module.vpc.private_route_table_ids
#   security_group_ids = var.install_eks_cluster ? [module.eks[0].cluster_primary_security_group_id] : [""]
# }

# resource "hcp_consul_cluster" "main" {
#   cluster_id      = var.cluster_id
#   hvn_id          = hcp_hvn.main.hvn_id
#   public_endpoint = true
#   tier            = var.tier
#   min_consul_version = "v1.14.0"
# }

data "hcp_consul_cluster"  "main" {
  cluster_id = "eks3"
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = data.hcp_consul_cluster.main.id
}

module "eks_consul_client" {
  # source  = "hashicorp/hcp-consul/aws//modules/hcp-eks-client"
  # version = "~> 0.8.9"
  source = "../../modules/hcp-eks-client/"

  boostrap_acl_token    = hcp_consul_cluster_root_token.token.secret_id
  cluster_id            = data.hcp_consul_cluster.main.cluster_id
  # strip out `https://` from the public url
  consul_hosts          = tolist([substr(data.hcp_consul_cluster.main.consul_public_endpoint_url, 8, -1)])
  consul_version        = data.hcp_consul_cluster.main.consul_version
  datacenter            = data.hcp_consul_cluster.main.datacenter
  k8s_api_endpoint      = var.install_eks_cluster ? module.eks[0].cluster_endpoint : ""

  # The EKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [module.eks]
}

module "demo_app" {
  count   = var.install_demo_app ? 1 : 0
  # source  = "hashicorp/hcp-consul/aws//modules/k8s-demo-app"
  # version = "~> 0.8.9"

  source = "../../modules/k8s-demo-app/"

  depends_on = [module.eks_consul_client]
}
