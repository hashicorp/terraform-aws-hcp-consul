provider "nomad" {
  address = "http://${aws_instance.nomad_host[0].public_ip}:8081"
  http_auth = "nomad:${var.nomad_token}"
}

resource "nomad_job" "hashicups" {
    count = var.install_demo_app ? 1 : 0
    provider = nomad
    jobspec = file("${path.module}/templates/hashicups.nomad")
    hcl2 {
    enabled = true
    }
}
resource "nomad_job" "hashicups-frontend" {
count = var.install_demo_app ? 1 : 0
  jobspec = file("${path.module}/templates/hashicups-frontend.nomad")
  hcl2 {
    enabled = true
  }
}
resource "time_sleep" "wait_15_seconds" {
    
  depends_on = [nomad_job.hashicups-frontend]

  create_duration = "15s"
}
resource "nomad_job" "hashicups-frontend-v2" {
    count = var.install_demo_app ? 1 : 0
  jobspec = file("${path.module}/templates/hashicups-frontend-v2.nomad")
  hcl2 {
    enabled = true
  }
  depends_on = [
    time_sleep.wait_15_seconds
  ]
}
