# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  secret_prefix = random_id.id.dec
  scope         = random_id.id.dec

  lb_port          = 80
  frontend_port    = 3000
  public_api_port  = 7070
  payment_api_port = 8080
  product_api_port = 9090
  product_db_port  = 5432
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-hirsute-21.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group_rule" "allow_http_inbound" {
  count       = length(var.allowed_http_cidr_blocks) >= 1 ? 1 : 0
  type        = "ingress"
  from_port   = local.lb_port
  to_port     = local.lb_port
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidr_blocks

  security_group_id = var.security_group_id
}

resource "aws_ecs_cluster" "clients" {
  name               = "hcp-ecs-cluster-${random_id.id.dec}"
  #capacity_providers = ["FARGATE"] removed as it is no longer an option as of 0.5.0
  
  depends_on = [var.nat_public_ips]
}

#new resource as aws_ecs_cluster 0.5.0+ removed capacity_providers option 

resource "aws_ecs_cluster_capacity_providers" "clients" {
  cluster_name = aws_ecs_cluster.clients.name

  capacity_providers = ["FARGATE"]

}

resource "random_id" "id" {
  byte_length = 2
}

resource "aws_secretsmanager_secret" "bootstrap_token" {
  name                    = "${local.secret_prefix}-bootstrap-token"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "bootstrap_token" {
  secret_id     = aws_secretsmanager_secret.bootstrap_token.id
  secret_string = var.root_token
}

resource "aws_secretsmanager_secret" "ca_cert" {
  name                    = "${local.secret_prefix}-client-ca-cert"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ca_cert" {
  secret_id     = aws_secretsmanager_secret.ca_cert.id
  secret_string = base64decode(var.client_ca_file)
}

resource "aws_secretsmanager_secret" "gossip_key" {
  name                    = "${local.secret_prefix}-gossip-encryption-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "gossip_key" {
  secret_id     = aws_secretsmanager_secret.gossip_key.id
  secret_string = var.client_gossip_key
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${local.secret_prefix}-ecs-client"
}
