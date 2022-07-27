locals {
  vpc_region       = "{{ .VPCRegion }}"
  hvn_region       = "{{ .HVNRegion }}"
  cluster_id       = "{{ .ClusterID }}"
  hvn_id           = "{{ .ClusterID }}-hvn"
  install_demo_app = true
  ssh              = true
}

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
  }

}

provider "aws" {
  region = local.vpc_region
}

provider "consul" {
  address    = hcp_consul_cluster.main.consul_public_endpoint_url
  datacenter = hcp_consul_cluster.main.datacenter
  token      = hcp_consul_cluster_root_token.token.secret_id
}

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.10.0"

  name                 = "${local.cluster_id}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets      = []
  enable_dns_hostnames = true
}

resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id
  cloud_provider = "aws"
  region         = local.hvn_region
  cidr_block     = "172.25.32.0/20"
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.7.2"

  hvn             = hcp_hvn.main
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  route_table_ids = module.vpc.public_route_table_ids
}

resource "hcp_consul_cluster" "main" {
  cluster_id      = local.cluster_id
  hvn_id          = hcp_hvn.main.hvn_id
  public_endpoint = true
  tier            = "development"
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "hcp_ec2_key_pair" {
  count      = local.ssh ? 1 : 0
  key_name   = "hcp-ec2-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "ssh_key" {
  count           = local.ssh ? 1 : 0
  filename        = "${aws_key_pair.key_pair.key_name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "400"
}

module "aws_ec2_consul_client" {
  source  = "hashicorp/hcp-consul/aws//modules/hcp-ec2-client"
  version = "~> 0.7.2"

  ssh_keyname              = local.ssh ? aws_key_pair.key_pair.key_name : ""
  subnet_id                = module.vpc.public_subnets[0]
  security_group_id        = module.aws_hcp_consul.security_group_id
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  client_config_file       = hcp_consul_cluster.main.consul_config_file
  client_ca_file           = hcp_consul_cluster.main.consul_ca_file
  root_token               = hcp_consul_cluster_root_token.token.secret_id
  consul_version           = hcp_consul_cluster.main.consul_version
  install_demo_app         = local.install_demo_app
  vpc_id                   = module.vpc.vpc_id
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

output "nomad_url" {
  value = "http://${module.aws_ec2_consul_client.public_ip}:8081"
}

output "hashicups_url" {
  value = "http://${module.aws_ec2_consul_client.public_ip}"
}
output "consul_export" {
  value     = <<EOF
  export CONSUL_HTTP_ADDR="${hcp_consul_cluster.main.consul_public_endpoint_url}"
  export CONSUL_HTTP_TOKEN="${hcp_consul_cluster_root_token.token.secret_id}"
  EOF
  sensitive = true
}
output "nomad_export" {
  value     = <<EOF
  export NOMAD_HTTP_AUTH="nomad:${hcp_consul_cluster_root_token.token.secret_id}"
  export NOMAD_ADDR="http://${module.aws_ec2_consul_client.public_ip}:8081"
  EOF
  sensitive = true
}
output "next_steps" {
  value = local.install_demo_app ? "Hashicups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token." : null
}
output "ssh_to_client" {
  value = local.ssh ? "ssh -i ${local_file.ssh_key[0].filename} ubuntu@${module.aws_ec2_consul_client.public_ip}" : null
}
output "connect_with_ssm" {
  value = "aws ssm start-session --target ${module.aws_ec2_consul_client.host_id} --region ${local.vpc_region}"
}
output "howto_connect_to_nomad" {
  value = <<EOF
  "In order to get access to both nomad and consul from the command line run the following commands:
  ${local.install_demo_app ? "eval $(terraform output nomad_export)" : ""}
  eval $(terraform output consul_export)
  This will set the environment variables so you have access to the deployment
  EOF
}
