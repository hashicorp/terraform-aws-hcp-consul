data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.10.0"

  azs                  = data.aws_availability_zones.available.names
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true
  name                 = "${var.cluster_id}-vpc"
  private_subnets      = []
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
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
  subnet_ids      = module.vpc.public_subnets
  route_table_ids = module.vpc.public_route_table_ids
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

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "hcp_ec2" {
  public_key = tls_private_key.ssh.public_key_openssh
  key_name   = "hcp-ec2-key-${var.cluster_id}"
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "400"
  filename        = "${path.module}/${aws_key_pair.hcp_ec2.key_name}.pem"
}

module "aws_ec2_consul_client" {
  source  = "hashicorp/hcp-consul/aws//modules/hcp-ec2-client"
  version = "~> 0.11.0"

  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  client_ca_file           = hcp_consul_cluster.main.consul_ca_file
  client_config_file       = hcp_consul_cluster.main.consul_config_file
  consul_version           = hcp_consul_cluster.main.consul_version
  nat_public_ips           = module.vpc.nat_public_ips
  install_demo_app         = var.install_demo_app
  root_token               = hcp_consul_cluster_root_token.token.secret_id
  security_group_id        = module.aws_hcp_consul.security_group_id
  ssh_key                  = tls_private_key.ssh.private_key_pem
  ssh_keyname              = aws_key_pair.hcp_ec2.key_name
  ssm                      = var.ssm
  subnet_id                = module.vpc.public_subnets[0]
  vpc_id                   = module.vpc.vpc_id
}

module "hashicups" {
  count = var.install_demo_app ? 1 : 0

  source  = "hashicorp/hcp-consul/aws/modules/ec2-demo-app"
  version = "~> 0.11.0"

  depends_on = [
    module.aws_ec2_consul_client
  ]
}
