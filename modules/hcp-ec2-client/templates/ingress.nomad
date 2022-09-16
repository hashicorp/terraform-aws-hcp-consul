job "ingress-demo" {

  datacenters = ["dc1"]

  group "ingress-group" {

    network {
      mode = "bridge"

      port "inbound" {
        static = 80
        to     = 80
      }
    }

    service {
      name = "hashicups-ingress"
      port = "80"
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
