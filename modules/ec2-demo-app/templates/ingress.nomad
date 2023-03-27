# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "ingress-demo" {

  datacenters = ["dc1"]

  group "ingress-group" {

    network {
      mode = "bridge"

      port "http" {
        static = 80
        to     = 80
      }
    }

    service {
      name = "hashicups-ingress"
      port = "http"

      connect {
        gateway {
          proxy {
          }

          ingress {
            listener {
              port     = 80
              protocol = "http"

              service {
                name  = "frontend"
                hosts = ["*"]
              }
            }
          }
        }
      }
    }
  }
}
