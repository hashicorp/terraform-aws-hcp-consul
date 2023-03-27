# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

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

  provider_meta "hcp" {
    module_name = "hcp-consul"
  }
}

provider "aws" {
  region = var.vpc_region
}

provider "consul" {
  address    = hcp_consul_cluster.main.consul_public_endpoint_url
  datacenter = hcp_consul_cluster.main.datacenter
  token      = hcp_consul_cluster_root_token.token.secret_id
}

provider "nomad" {
  address   = "http://${module.aws_ec2_consul_client.public_ip}:8081"
  http_auth = "nomad:${hcp_consul_cluster_root_token.token.secret_id}"
}

