data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.10.0"

  name                 = "${var.cluster_id}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
}

resource "hcp_hvn" "main" {
  hvn_id         = var.hvn_id
  cloud_provider = "aws"
  region         = var.hvn_region
  cidr_block     = var.hvn_cidr_block
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.11.0"

  hvn             = hcp_hvn.main
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  route_table_ids = module.vpc.private_route_table_ids
}

resource "hcp_consul_cluster" "main" {
  cluster_id      = var.cluster_id
  hvn_id          = hcp_hvn.main.hvn_id
  public_endpoint = true
  tier            = var.tier
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

module "aws_ecs_cluster" {
  source  = "hashicorp/hcp-consul/aws//modules/hcp-ecs-client"
  version = "~> 0.11.0"

  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  client_ca_file           = hcp_consul_cluster.main.consul_ca_file
  client_config_file       = hcp_consul_cluster.main.consul_config_file
  client_gossip_key        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]
  client_retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_url               = hcp_consul_cluster.main.consul_private_endpoint_url
  consul_version           = substr(hcp_consul_cluster.main.consul_version, 1, -1)
  datacenter               = hcp_consul_cluster.main.datacenter
  nat_public_ips           = module.vpc.nat_public_ips
  private_subnet_ids       = module.vpc.private_subnets
  public_subnet_ids        = module.vpc.public_subnets
  region                   = var.vpc_region
  root_token               = hcp_consul_cluster_root_token.token.secret_id
  security_group_id        = module.aws_hcp_consul.security_group_id
  vpc_id                   = module.vpc.vpc_id
}
