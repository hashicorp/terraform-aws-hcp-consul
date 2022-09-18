variable "public_api_port" {
  type    = number
  default = 7070
}

variable "payment_api_port" {
  type    = number
  default = 8080
}

variable "product_api_port" {
  type    = number
  default = 9090
}

variable "product_db_port" {
  type    = number
  default = 5432
}

job "hashicups" {
  datacenters = ["dc1"]

  group "public-api" {
    network {
      mode = "bridge"

      port "http" {
        static = var.public_api_port
      }
    }

    service {
      name = "public-api"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            config {
              protocol = "http"
            }

            upstreams {
              destination_name = "product-api"
              local_bind_port  = var.product_api_port
            }

            upstreams {
              destination_name = "payment-api"
              local_bind_port  = var.payment_api_port
            }
          }
        }
      }
    }

    task "public-api" {
      driver = "docker"

      resources {
        cpu    = 300 # MHz
        memory = 128 # MB
      }

      config {
        image = "hashicorpdemoapp/public-api:v0.0.6"
        ports = ["http"]
      }

      env {
        BIND_ADDRESS    = ":${var.public_api_port}"
        PRODUCT_API_URI = "http://localhost:${var.product_api_port}"
        PAYMENT_API_URI = "http://localhost:${var.payment_api_port}"
      }

      restart {
        interval = "30m"
        attempts = 10
        delay    = "15s"
        mode     = "fail"
      }
    }
  }

  group "payment-api" {
    network {
      mode = "bridge"

      port "http" {
        static = var.payment_api_port
      }
    }

    service {
      name = "payment-api"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            config {
              protocol = "http"
            }
          }
        }
      }
    }

    task "payment-api" {
      driver = "docker"

      resources {
        cpu    = 300 # MHz
        memory = 128 # MB
      }

      config {
        image = "hashicorpdemoapp/payments:v0.0.16"
        ports = ["http"]
      }

      restart {
        interval = "30m"
        attempts = 10
        delay    = "15s"
        mode     = "fail"
      }
    }
  }

  group "product-api" {
    network {
      mode = "bridge"

      port "http" {
        static = var.product_api_port
      }

      port "healthcheck" {
        to = -1
      }
    }

    service {
      name = "product-api"
      port = "http"

      check {
        type     = "http"
        path     = "/health"
        interval = "5s"
        timeout  = "2s"
        expose   = true
        port     = "healthcheck"
      }

      connect {
        sidecar_service {
          proxy {
            config {
              protocol = "http"
            }

            upstreams {
              destination_name = "product-db"
              local_bind_port  = var.product_db_port
            }
          }
        }
      }
    }

    task "product-api" {
      driver = "docker"

      resources {
        cpu    = 300 # MHz
        memory = 128 # MB
      }

      config {
        image = "hashicorpdemoapp/product-api:v0.0.20"
      }

      env {
        DB_CONNECTION = "host=localhost port=${var.product_db_port} user=postgres password=password dbname=products sslmode=disable"
        BIND_ADDRESS  = "localhost:${var.product_api_port}"
      }

      restart {
        interval = "30m"
        attempts = 10
        delay    = "15s"
        mode     = "fail"
      }
    }
  }

  group "product-db" {
    network {
      mode = "bridge"

      port "http" {
        static = var.product_db_port
      }
    }

    service {
      name = "product-db"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            config {
              protocol = "http"
            }
          }
        }
      }
    }

    task "db" {
      driver = "docker"

      resources {
        cpu    = 300 # MHz
        memory = 128 # MB
      }

      config {
        image = "hashicorpdemoapp/product-api-db:v0.0.20"
        ports = ["http"]
      }

      env {
        POSTGRES_DB       = "products"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "password"
      }

      restart {
        interval = "30m"
        attempts = 10
        delay    = "15s"
        mode     = "fail"
      }
    }
  }
}
