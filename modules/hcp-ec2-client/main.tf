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

resource "aws_security_group_rule" "allow_ssh_inbound" {
  count       = length(var.allowed_ssh_cidr_blocks) >= 1 ? 1 : 0
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.allowed_ssh_cidr_blocks

  security_group_id = var.security_group_id
}

resource "aws_security_group_rule" "allow_http_inbound" {
  count       = length(var.allowed_http_cidr_blocks) >= 1 ? 1 : 0
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = var.allowed_http_cidr_blocks

  security_group_id = var.security_group_id
}

resource "aws_instance" "consul_client_dashboard" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3a.micro"
  associate_public_ip_address = true
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  user_data = templatefile("${path.module}/templates/install.sh", {
    consul_version    = "1.10.2+ent",
    consul_config     = var.client_config_file,
    consul_ca         = base64decode(var.client_ca_file),
    demo_service_name = "dashboard-service"
    consul_acl_token  = var.root_token,
    consul_service = templatefile("${path.module}/templates/service", {
      service_name = "consul",
      service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
    }),
    demo_service = templatefile("${path.module}/templates/service", {
      service_name = "demo",
      service_cmd  = "/usr/bin/dashboard-service",
    }),
    sidecar_service = templatefile("${path.module}/templates/service", {
      service_name = "sidecar",
      service_cmd  = "/usr/bin/consul connect envoy -sidecar-for dashboard-service -token ${var.root_token}",
    }),
  })

  tags = {
    Name = "${random_id.id.dec}-hcp-consul-client-dashboard-instance"
  }

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }
}

resource "aws_instance" "consul_client_counting" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3a.micro"
  associate_public_ip_address = true
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  user_data = templatefile("${path.module}/templates/install.sh", {
    consul_version    = "1.10.2+ent",
    consul_config     = var.client_config_file,
    consul_ca         = base64decode(var.client_ca_file),
    demo_service_name = "counting-service"
    consul_acl_token  = var.root_token,
    consul_service = templatefile("${path.module}/templates/service", {
      service_name = "consul",
      service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
    }),
    demo_service = templatefile("${path.module}/templates/service", {
      service_name = "demo",
      service_cmd  = "/usr/bin/counting-service",
    }),
    sidecar_service = templatefile("${path.module}/templates/service", {
      service_name = "sidecar",
      service_cmd  = "/usr/bin/consul connect envoy -sidecar-for counting-service -token ${var.root_token}",
    }),
  })

  tags = {
    Name = "${random_id.id.dec}-hcp-consul-client-counting-instance"
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
