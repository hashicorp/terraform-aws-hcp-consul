locals {
  secret_prefix = "consul-ecs-test"
  frontend_port = 80
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
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidr_blocks

  security_group_id = var.security_group_id
}

resource "aws_ecs_cluster" "clients" {
  name               = "${random_id.id.dec}-hcp-ecs-cluster"
  capacity_providers = ["FARGATE"]
}

resource "random_id" "id" {
  prefix      = "consul-client"
  byte_length = 8
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
  name = "something-log"
}

