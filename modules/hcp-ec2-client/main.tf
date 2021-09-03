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

resource "aws_instance" "consul_client" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3a.micro"
  key_name                    = aws_key_pair.key.key_name
  associate_public_ip_address = true
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]

  tags = {
    Name = "${random_id.id.dec}-hcp-consul-client-instance"
  }

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }

  provisioner "file" {
    content     = base64decode(var.client_config_file)
    destination = "/home/ubuntu/client_config.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "file" {
    content     = base64decode(var.client_ca_file)
    destination = "/home/ubuntu/ca.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/client_acl.json", {
      consul_acl_token = var.root_token
    })
    destination = "/home/ubuntu/client_acl.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "${path.module}/templates/consul.service"
    destination = "/home/ubuntu/consul.service"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/install-consul.sh", {
      consul_version = "1.10.2+ent",
    })
    destination = "/home/ubuntu/install-consul.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/install-consul.sh",
      "/home/ubuntu/install-consul.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.key.private_key_pem
      host        = self.public_ip
    }
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${random_id.id.dec}-ssh-key.pem"
}

resource "aws_key_pair" "key" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.key.public_key_openssh
}

resource "random_id" "id" {
  prefix      = "consul-client"
  byte_length = 8
}
