variable "frontend_port" {
  type    = number
  default = 3000
}

variable "public_api_port" {
  type    = number
  default = 7070
}

job "hashicups_frontend" {
  datacenters = ["dc1"]

  group "frontend" {
    count = 1

    update {
      max_parallel = 1
      canary       = 1
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
          proxy {
            upstreams {
              destination_name = "public-api"
              local_bind_port  = var.public_api_port
            }
          }
        }
      }
    }

    task "frontend" {
      driver = "docker"

      resources {
        cpu    = 300 # MHz
        memory = 128 # MB
      }

      config {
        image = "hashicorpdemoapp/frontend-nginx:v1.0.9"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "local/default.conf"
          target = "/etc/nginx/conf.d/default.conf"
        }
      }

      env {
        NEXT_PUBLIC_PUBLIC_API_URL = "/"
        NEXT_PUBLIC_FOOTER_FLAG    = "HashiCups-v1"
        PORT                       = var.frontend_port
      }

      template {
        destination = "local/default.conf"
        data        = <<EOF
            upstream public_api_upstream {
              server {{ env "NOMAD_UPSTREAM_ADDR_public_api" }};
            }
          
            server {
              listen ${var.frontend_port};
              server_name localhost;

              server_tokens off;

              gzip on;
              gzip_proxied any;
              gzip_comp_level 4;
              gzip_types text/css application/javascript image/svg+xml;

              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection 'upgrade';
              proxy_set_header Host $host;

              location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
              }

              location /api {
                proxy_pass http://public_api_upstream;
              }
            }
          EOF
      }

      restart {
        interval = "30m"
        attempts = 15
        delay    = "30s"
        mode     = "fail"
      }
    }
  }
}
