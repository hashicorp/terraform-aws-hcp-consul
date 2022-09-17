data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "host" {
  name_prefix = "host"
  description = "HCP Consul security group"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  count = length(var.allowed_ssh_cidr_blocks) >= 1 ? 1 : 0

  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.allowed_ssh_cidr_blocks

  security_group_id = aws_security_group.host.id
}

resource "aws_security_group_rule" "allow_nomad_inbound" {
  count = length(var.allowed_http_cidr_blocks) >= 1 ? 1 : 0

  type        = "ingress"
  from_port   = 8081
  to_port     = 8081
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidr_blocks

  security_group_id = aws_security_group.host.id
}

resource "aws_security_group_rule" "allow_http_inbound" {
  count = length(var.allowed_http_cidr_blocks) >= 1 ? 1 : 0

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidr_blocks

  security_group_id = aws_security_group.host.id
}

# Set up the instance profile and iam role to enable SSM
resource "aws_iam_role" "hcp_ec2_iam_role" {
  count = var.ssm ? 1 : 0

  name_prefix        = "hcp_ec2_role"
  description        = "The role for the developer resources EC2"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
  EOF
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  count = var.ssm ? 1 : 0

  role       = aws_iam_role.hcp_ec2_iam_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "hcp_ec2" {
  count = var.ssm ? 1 : 0

  role        = aws_iam_role.hcp_ec2_iam_role[0].name
  name_prefix = "hcp_ec2_profile"
}

# Create the Consul and Nomad client
resource "aws_instance" "host" {
  count = 1

  ami                         = data.aws_ami.ubuntu.id
  associate_public_ip_address = length(var.igw_id) > 0
  iam_instance_profile        = length(aws_iam_instance_profile.hcp_ec2) >= 1 ? aws_iam_instance_profile.hcp_ec2[0].name : null
  instance_type               = "t3.medium"
  key_name                    = var.ssh_keyname
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.host.id, var.security_group_id]

  user_data = templatefile("${path.module}/templates/user_data.sh", {
    setup = base64gzip(templatefile("${path.module}/templates/setup.sh", {
      # Consul config
      consul_config    = var.client_config_file,
      consul_ca        = var.client_ca_file,
      consul_acl_token = var.root_token,
      consul_version   = var.consul_version,
      consul_service = base64encode(templatefile("${path.module}/templates/service", {
        service_name = "consul",
        service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      node_id = var.node_id,

      # Nomad config
      install_demo_app = var.install_demo_app,
      nomad_service = base64encode(templatefile("${path.module}/templates/service", {
        service_name = "nomad",
        service_cmd  = "/usr/bin/nomad agent -dev-connect -consul-token=${var.root_token}",
      })),

      # Nginx config
      nginx_conf = base64encode(file("${path.module}/templates/nginx.conf")),
      vpc_cidr   = var.vpc_cidr
    })),
  })

  tags = {
    Name = "${random_id.id.dec}-hcp-client"
  }

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }

}

resource "random_id" "id" {
  prefix      = "consul-client"
  byte_length = 8
}
