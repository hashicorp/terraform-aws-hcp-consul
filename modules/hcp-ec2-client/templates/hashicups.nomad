job "hashicups" {
  datacenters = ["dc1"]

  group "frontend" {
    network {
      mode = "bridge"
      port "http" {
        static = 80
      }
    }

    service {
      name = "frontend"
      port = "80"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "product-public-api"
              local_bind_port  = 18080
            }            
          }
        }
      }
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/frontend:v0.0.5"
        ports = ["http"]
      }
    }
  }

  group "product-public-api" {
    network {
      mode = "bridge"
    }

    service {
      name = "product-public-api"
      port = "8080"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "product-api"
              local_bind_port  = 5000
            }            
            upstreams {
              destination_name = "payment-api"
              local_bind_port  = 5001
            }
          }
        }
      }
    }

    task "product-public-api" {
      driver = "docker"

      config {
        image   = "hashicorpdemoapp/public-api:v0.0.5"
      }

      env {
        PRODUCT_API_URI = "http://localhost:5000"
        PAYMENT_API_URI = "http://localhost:5001"
      }
    }
  }

  group "payment-api" {
    network {
      mode = "bridge"
    }

    service {
      name = "payment-api"
      port = "8080"

      connect {
        sidecar_service {}
      }
    }

    task "payment-api" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/payments:v0.0.3"
      }
    }
  }

  group "product-api" {
    network {
      mode = "bridge"
      port "healthcheck" {
        to = -1
      }
    }

    service {
      name = "product-api"
      port = "9090"

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
            upstreams {
              destination_name = "product-db"
              local_bind_port  = 5000
            }
          }
        }
      }
    }

    task "product-api" {
      driver = "docker"

      config {
        image   = "hashicorpdemoapp/product-api:v0.0.18"
      }

      env {
        CONFIG_FILE = "/config/config.json"
				DB_CONNECTION = "host=localhost port=5000 user=postgres password=password dbname=products sslmode=disable"
				BIND_ADDRESS = "0.0.0.0:9090"
      }
    }
  }

  group "product-db" {
    network {
      mode = "bridge"
    }

    service {
      name = "product-db"
      port = "5432"

      connect {
        sidecar_service {}
      }
    }

    task "db" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/product-api-db:v0.0.17"
      }

      env {
        POSTGRES_DB       = "products"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "password"
      }
    }
  }
}
