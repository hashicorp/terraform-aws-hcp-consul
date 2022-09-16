provider "nomad" {
  address   = "http://${aws_instance.nomad_host[0].public_ip}:8081"
  http_auth = "nomad:${var.root_token}"
}

# wait for nomad server to be ready before deploying nomad jobs
resource "time_sleep" "wait_for_client" {
  create_duration = "90s"

  depends_on = [aws_instance.nomad_host]
}

resource "nomad_job" "hashicups" {
  count = var.install_demo_app ? 1 : 0

  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    time_sleep.wait_for_client,
    aws_instance.nomad_host
  ]
}

resource "nomad_job" "hashicups-frontend" {
  count    = var.install_demo_app ? 1 : 0
  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups-frontend.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    nomad_job.hashicups,
    consul_config_entry.service_default_frontend,
    aws_instance.nomad_host
  ]
}

resource "time_sleep" "wait_15_seconds" {
  depends_on = [nomad_job.hashicups-frontend]

  create_duration = "15s"
}

resource "nomad_job" "hashicups-frontend-v2" {
  count    = var.install_demo_app ? 1 : 0
  provider = nomad
  jobspec  = file("${path.module}/templates/hashicups-frontend-v2.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    time_sleep.wait_15_seconds,
    consul_config_entry.service_default_frontend,
    aws_instance.nomad_host
  ]
}


resource "nomad_job" "hashicups-ingress" {
  count    = var.install_demo_app ? 1 : 0
  provider = nomad
  jobspec  = file("${path.module}/templates/ingress.nomad")

  hcl2 {
    enabled = true
  }

  depends_on = [
    nomad_job.hashicups-frontend-v2,
    nomad_job.hashicups-frontend,
    aws_instance.nomad_host
  ]
}
