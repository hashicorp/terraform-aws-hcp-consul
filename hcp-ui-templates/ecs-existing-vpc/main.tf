locals {
  vpc_region             = "{{ .VPCRegion }}"
  hvn_region             = "{{ .HVNRegion }}"
  cluster_id             = "{{ .ClusterID }}"
  hvn_id                 = "{{ .ClusterID }}-hvn"
  vpc_id                 = "{{ .VPCID }}"
  public_route_table_id  = "{{ .PublicRouteTableID }}"
  private_route_table_id = "{{ .PrivateRouteTableID }}"
  public_subnet1         = "{{ .PublicSubnet1 }}"
  public_subnet2         = "{{ .PublicSubnet2 }}"
  private_subnet1        = "{{ .PrivateSubnet1 }}"
  private_subnet2        = "{{ .PrivateSubnet2 }}"
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

resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id
  cloud_provider = "aws"
  region         = local.hvn_region
  cidr_block     = "172.25.32.0/20"
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.6.0"

  hvn    = hcp_hvn.main
  vpc_id = local.vpc_id
  subnet_ids = concat(
    [local.private_subnet1, local.private_subnet2],
    [local.public_subnet1, local.public_subnet2],
  )
  route_table_ids = concat(
    [local.private_route_table_id],
    [local.public_route_table_id],
  )
}

resource "hcp_consul_cluster" "main" {
  cluster_id      = local.cluster_id
  hvn_id          = hcp_hvn.main.hvn_id
  public_endpoint = true
  tier            = "development"
}

resource "consul_config_entry" "service_intentions" {
  name = "*"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "*"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

module "aws_ecs_cluster" {
  source  = "hashicorp/hcp-consul/aws//modules/hcp-ecs-client"
  version = "~> 0.6.0"

  private_subnet_ids       = [local.private_subnet1, local.private_subnet2]
  public_subnet_ids        = [local.public_subnet1, local.public_subnet2]
  vpc_id                   = local.vpc_id
  security_group_id        = module.aws_hcp_consul.security_group_id
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  client_config_file       = hcp_consul_cluster.main.consul_config_file
  client_ca_file           = hcp_consul_cluster.main.consul_ca_file
  client_gossip_key        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]
  client_retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  region                   = local.vpc_region
  root_token               = hcp_consul_cluster_root_token.token.secret_id
  consul_url               = hcp_consul_cluster.main.consul_private_endpoint_url
  consul_version           = substr(hcp_consul_cluster.main.consul_version, 1, -1)
  datacenter               = hcp_consul_cluster.main.datacenter

  provisioner "local-exec" {
    command = "echo Application startup takes ~2 minutes."
  }
}
resource "consul_config_entry" "service_intentions_db" {
  name = "product-db"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "product-api"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_product" {
  name = "product-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "product-public-api"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_payment" {
  name = "payment-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "product-public-api"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_public_api" {
  name = "product-public-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "frontend"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
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

output "hashicups_url" {
  value = "http://${module.aws_ecs_cluster.hashicups_url}"
}

output "next_steps" {
  value = "Hashicups Application will be ready in ~2 minutes"
}
