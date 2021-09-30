data "aws_availability_zones" "available" {}

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

# The HVN created in HCP
resource "hcp_hvn" "main" {
  hvn_id         = var.hvn_id
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = var.hvn_cidr_block
}

module "aws_hcp_consul" {
  source          = "../../../terraform-aws-hcp-consul"
  hvn_id          = hcp_hvn.main.hvn_id
  vpc_id          = module.vpc.vpc_id
  route_table_ids = module.vpc.public_route_table_ids

  # This is required because the hcp_hvn.main.hvn_id does not block
  # on HVN creation, and thus we need to wait until the HVN is
  # successfully created.
  depends_on = [hcp_hvn.main]
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

module "aws_ec2_consul_client" {
  depends_on               = [module.aws_hcp_consul]
  source                   = "../../modules/hcp-ec2-client"
  subnet_id                = module.vpc.public_subnets[0]
  security_group_id        = module.aws_hcp_consul.security_group_ids[0]
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  client_config_file       = hcp_consul_cluster.main.consul_config_file
  client_ca_file           = hcp_consul_cluster.main.consul_ca_file
  root_token               = hcp_consul_cluster_root_token.token.secret_id
}
