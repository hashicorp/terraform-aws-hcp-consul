# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "nomad_job" "hashicups" {
  jobspec               = file("${path.module}/templates/hashicups.nomad")
  deregister_on_destroy = false

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "hashicups_frontend" {
  jobspec               = file("${path.module}/templates/hashicups-frontend.nomad")
  deregister_on_destroy = false

  hcl2 {
    enabled = true
  }
}

resource "time_sleep" "wait_for_frontend" {
  depends_on = [nomad_job.hashicups_frontend]

  create_duration = "30s"
}

resource "nomad_job" "hashicups_frontend_v2" {
  jobspec               = file("${path.module}/templates/hashicups-frontend-v2.nomad")
  deregister_on_destroy = false

  hcl2 {
    enabled = true
  }

  depends_on = [
    time_sleep.wait_for_frontend
  ]
}

resource "nomad_job" "ingress" {
  jobspec               = file("${path.module}/templates/ingress.nomad")
  deregister_on_destroy = false

  hcl2 {
    enabled = true
  }

  depends_on = [
    time_sleep.wait_for_frontend
  ]
}
