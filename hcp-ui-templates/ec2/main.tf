locals {
  vpc_region       = "{{ .VPCRegion }}"
  hvn_region       = "{{ .HVNRegion }}"
  cluster_id       = "{{ .ClusterID }}"
  hvn_id           = "{{ .ClusterID }}-hvn"
  install_demo_app = true
  ssh              = true
  ssm              = true
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

  azs                  = data.aws_availability_zones.available.names
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true
  name                 = "${local.cluster_id}-vpc"
  private_subnets      = []
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id
  cloud_provider = "aws"
  region         = local.hvn_region
  cidr_block     = "172.25.32.0/20"
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.9.1"

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

resource "aws_key_pair" "hcp_ec2" {
  count = local.ssh ? 1 : 0

  public_key = tls_private_key.ssh.public_key_openssh
  key_name   = "hcp-ec2-key-${local.cluster_id}"
}

resource "local_file" "ssh_key" {
  count = local.ssh ? 1 : 0

  content         = tls_private_key.ssh.private_key_pem
  file_permission = "400"
  filename        = "${path.module}/${aws_key_pair.hcp_ec2[0].key_name}.pem"
}

module "aws_ec2_consul_client" {
  source  = "hashicorp/hcp-consul/aws//modules/hcp-ec2-client"
  version = "~> 0.9.1"

  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  client_ca_file           = hcp_consul_cluster.main.consul_ca_file
  client_config_file       = hcp_consul_cluster.main.consul_config_file
  consul_version           = hcp_consul_cluster.main.consul_version
  nat_public_ips           = module.vpc.nat_public_ips
  install_demo_app         = local.install_demo_app
  root_token               = hcp_consul_cluster_root_token.token.secret_id
  security_group_id        = module.aws_hcp_consul.security_group_id
  ssh_keyname              = local.ssh ? aws_key_pair.hcp_ec2[0].key_name : ""
  ssm                      = local.ssm
  subnet_id                = module.vpc.public_subnets[0]
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

output "next_steps" {
  value = local.install_demo_app ? "HashiCups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token." : null
}

output "howto_connect" {
  value = <<EOF
  ${local.install_demo_app ? "The demo app, HashiCups, is installed on a Nomad server we have deployed for you." : ""}
  ${local.install_demo_app ? "To access Nomad using your local client run the following command:" : ""}
  ${local.install_demo_app ? "export NOMAD_HTTP_AUTH=nomad:$(terraform output consul_root_token)" : ""}
  ${local.install_demo_app ? "export NOMAD_ADDR=http://${module.aws_ec2_consul_client.public_ip}:8081" : ""}

  To access Consul from your local client run:
  export CONSUL_HTTP_ADDR="${hcp_consul_cluster.main.consul_public_endpoint_url}"
  export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token)
  
  To connect to the ec2 instance deployed: 
${local.ssh ? "  - To access via SSH run: ssh -i ${abspath(local_file.ssh_key[0].filename)} ubuntu@${module.aws_ec2_consul_client.public_ip}" : ""}
${local.ssm ? "  - To access via SSM run: aws ssm start-session --target ${module.aws_ec2_consul_client.host_id} --region ${local.vpc_region}" : ""}
  EOF
}
