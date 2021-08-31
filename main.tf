terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.15.0"
    }
  }
}

locals {
  ingress_consul_rules = [
    {
      description = "Consul LAN Serf (tcp)"
      port        = 8301
      protocol    = "tcp"
    },
    {
      description = "Consul LAN Serf (udp)"
      port        = 8301
      protocol    = "udp"
    },
  ]

  hcp_consul_security_groups = flatten([
    for _, sg in var.security_group_ids : [
      for _, rule in local.ingress_consul_rules : {
        security_group_id = sg
        description       = rule.description
        port              = rule.port
        protocol          = rule.protocol
      }
    ]
  ])
}

data "hcp_hvn" "selected" {
  hvn_id = var.hvn_id
}

data "aws_region" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "hcp_aws_network_peering" "default" {
  peering_id      = "${data.hcp_hvn.selected.hvn_id}-peering"
  hvn_id          = data.hcp_hvn.selected.hvn_id
  peer_vpc_id     = data.aws_vpc.selected.id
  peer_account_id = data.aws_vpc.selected.owner_id
  peer_vpc_region = data.aws_region.current.name
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.default.provider_peering_id
  auto_accept               = true
}

resource "hcp_hvn_route" "peering_route" {
  depends_on       = [aws_vpc_peering_connection_accepter.peer]
  hvn_link         = data.hcp_hvn.selected.self_link
  hvn_route_id     = "${data.hcp_hvn.selected.hvn_id}-peering-route"
  destination_cidr = data.aws_vpc.selected.cidr_block
  target_link      = hcp_aws_network_peering.default.self_link
}

resource "aws_route" "peering" {
  count                     = length(var.route_table_ids)
  route_table_id            = var.route_table_ids[count.index]
  destination_cidr_block    = data.hcp_hvn.selected.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.vpc_peering_connection_id
}

resource "aws_security_group_rule" "hcp_consul" {
  count             = length(local.hcp_consul_security_groups)
  description       = local.hcp_consul_security_groups[count.index].description
  protocol          = local.hcp_consul_security_groups[count.index].protocol
  security_group_id = local.hcp_consul_security_groups[count.index].security_group_id
  cidr_blocks       = [data.hcp_hvn.selected.cidr_block]
  from_port         = local.hcp_consul_security_groups[count.index].port
  to_port           = local.hcp_consul_security_groups[count.index].port
  type              = "ingress"
}
