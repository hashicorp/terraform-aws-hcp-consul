provider "nomad" {
  address   = "http://${aws_instance.host[0].public_ip}:8081"
  http_auth = "nomad:${var.root_token}"
}

# wait for Consul and Nomad services to be ready
resource "time_sleep" "wait_for_startup" {
  create_duration = "90s"

  depends_on = [aws_instance.host]
}

resource "nomad_job" "hashicups" {
  count = var.install_demo_app ? 1 : 0

  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [time_sleep.wait_for_startup]
}

resource "nomad_job" "hashicups_frontend" {
  count    = var.install_demo_app ? 1 : 0
  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups_frontend.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    time_sleep.wait_for_startup,
    consul_config_entry.service_default_frontend
  ]
}

resource "time_sleep" "wait_for_frontend" {
  depends_on = [nomad_job.hashicups_frontend]

  create_duration = "15s"
}

resource "nomad_job" "hashicups_frontend_v2" {
  count    = var.install_demo_app ? 1 : 0
  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups_frontend_v2.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [time_sleep.wait_for_frontend]
}

resource "nomad_job" "ingress" {
  count    = var.install_demo_app ? 1 : 0
  provider = nomad
  jobspec  = file("${path.module}/templates/ingress.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [nomad_job.hashicups_frontend_v2]
}
