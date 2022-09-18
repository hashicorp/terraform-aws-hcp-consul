provider "nomad" {
  address   = "http://${aws_instance.host.public_ip}:8081"
  http_auth = "nomad:${var.root_token}"
}

# wait for Consul and Nomad services to be ready
resource "time_sleep" "wait_for_startup" {
  create_duration = "2m"

  depends_on = [aws_instance.host]
}

resource "nomad_job" "hashicups" {
  count = var.install_demo_app ? 1 : 0

  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    aws_instance.host,
    aws_security_group_rule.allow_nomad_inbound,
    time_sleep.wait_for_startup
  ]
}

resource "nomad_job" "hashicups_frontend" {
  count = var.install_demo_app ? 1 : 0

  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups-frontend.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    aws_instance.host,
    aws_security_group_rule.allow_nomad_inbound,
    consul_config_entry.service_default_frontend,
    time_sleep.wait_for_startup
  ]
}

resource "time_sleep" "wait_for_frontend" {
  depends_on = [nomad_job.hashicups_frontend]

  create_duration = "30s"
}

resource "nomad_job" "hashicups_frontend_v2" {
  count = var.install_demo_app ? 1 : 0

  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups-frontend-v2.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    aws_instance.host,
    aws_security_group_rule.allow_nomad_inbound,
    consul_config_entry.service_default_frontend,
    time_sleep.wait_for_frontend
  ]
}

resource "nomad_job" "ingress" {
  count = var.install_demo_app ? 1 : 0

  provider = nomad
  jobspec  = file("${path.module}/templates/ingress.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    aws_instance.host,
    aws_security_group_rule.allow_nomad_inbound,
    consul_config_entry.ingress_gateway,
    time_sleep.wait_for_frontend
  ]
}
