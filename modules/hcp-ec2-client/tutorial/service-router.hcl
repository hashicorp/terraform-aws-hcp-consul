Kind = "service-router"
Name = "frontend"
Routes = [
  {
    Match {
      HTTP {
        PathPrefix = "/v1"
      }
    }

    Destination {
      Service = "frontend"
      ServiceSubset = "v1"
      prefixRewrite = "/"
    }
  },
  {
    Match {
      HTTP {
        PathPrefix = "/v2"
      }
    }

    Destination {
      Service = "frontend"
      ServiceSubset = "v2"
      prefixRewrite = "/"
    }
  },
  # NOTE: a default catch-all will send unmatched traffic to "web"
]
