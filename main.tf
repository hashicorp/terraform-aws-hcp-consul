terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.43.0"
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

  # If a list of security_group_ids was provided, construct a rule set.
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

data "aws_region" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "hcp_aws_network_peering" "default" {
  peering_id      = "${data.aws_vpc.selected.id}-peering"
  hvn_id          = var.hvn.hvn_id
  peer_vpc_id     = data.aws_vpc.selected.id
  peer_account_id = data.aws_vpc.selected.owner_id
  peer_vpc_region = data.aws_region.current.name
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.default.provider_peering_id
  auto_accept               = true
}

data "aws_subnet" "selected" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

resource "hcp_hvn_route" "peering_route" {
  count = length(var.subnet_ids)

  hvn_link         = var.hvn.self_link
  hvn_route_id     = var.subnet_ids[count.index]
  destination_cidr = data.aws_subnet.selected[count.index].cidr_block
  target_link      = hcp_aws_network_peering.default.self_link

  depends_on = [aws_vpc_peering_connection_accepter.peer]
}

resource "aws_route" "peering" {
  count = length(var.route_table_ids)

  route_table_id            = var.route_table_ids[count.index]
  destination_cidr_block    = var.hvn.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.vpc_peering_connection_id
}

# If a list of security_group_ids was provided, set rules on those.
resource "aws_security_group_rule" "hcp_consul_existing_grp" {
  count = length(local.hcp_consul_security_groups)

  description       = local.hcp_consul_security_groups[count.index].description
  protocol          = local.hcp_consul_security_groups[count.index].protocol
  security_group_id = local.hcp_consul_security_groups[count.index].security_group_id
  cidr_blocks       = [var.hvn.cidr_block]
  from_port         = local.hcp_consul_security_groups[count.index].port
  to_port           = local.hcp_consul_security_groups[count.index].port
  type              = "ingress"
}

# If no security_group_ids were provided, create a new security_group.
resource "aws_security_group" "hcp_consul" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  name_prefix = "hcp_consul"
  description = "HCP Consul security group"
  vpc_id      = data.aws_vpc.selected.id
}

# If no security_group_ids were provided, use the new security_group.
resource "aws_security_group_rule" "allow_lan_consul_gossip" {
  count = length(var.security_group_ids) == 0 ? length(local.ingress_consul_rules) : 0

  description       = local.ingress_consul_rules[count.index].description
  protocol          = local.ingress_consul_rules[count.index].protocol
  security_group_id = aws_security_group.hcp_consul[0].id
  cidr_blocks       = [var.hvn.cidr_block]
  from_port         = local.ingress_consul_rules[count.index].port
  to_port           = local.ingress_consul_rules[count.index].port
  type              = "ingress"
}

# If no security_group_ids were provided, allow egress on the new security_group.
resource "aws_security_group_rule" "allow_all_egress" {
  count             = length(var.security_group_ids) == 0 ? 1 : 0
  description       = "Allow egress access to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.hcp_consul[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

# If no security_group_ids were provided, allow self ingress on the new security_group.
resource "aws_security_group_rule" "allow_self" {
  count             = length(var.security_group_ids) == 0 ? 1 : 0
  description       = "Allow members of this security group to communicate over all ports"
  protocol          = "-1"
  security_group_id = aws_security_group.hcp_consul[0].id
  self              = true
  from_port         = 0
  to_port           = 0
  type              = "ingress"
}
