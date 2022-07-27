Kind = "service-router"
Name = "vfrontend"
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
    }
  },
  # NOTE: a default catch-all will send unmatched traffic to "web"
]
