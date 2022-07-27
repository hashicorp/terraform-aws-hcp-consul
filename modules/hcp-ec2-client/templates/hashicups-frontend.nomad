variable "frontend_port" {
  type = number
  default = 3000
}

job "hashicups-frontend" {
  datacenters = ["dc1"]
  
  group "frontend" {
    count = 1

    update {
      max_parallel = 1
      
      canary = 1
    }
    network {
      mode = "bridge"
      port "http" {
        static = var.frontend_port
      }
    }
    service {
      name = "frontend"
      port = "http"
      meta {
          version = "v1"
        }
      connect {
        sidecar_service {
        }
      }
    }
    task "frontend" {
      driver = "docker"
      resources {
        cpu = 300 # MHz
        memory = 128 # MB
       }
      config {
        
        image = "hashicorpdemoapp/frontend:v1.0.4"
        ports = ["http"]
      }
      env {
        NEXT_PUBLIC_PUBLIC_API_URL = "/"
        NEXT_PUBLIC_FOOTER_FLAG="Hashicups-v1"
        PORT="${var.frontend_port}"
      }
    }
  }
}
