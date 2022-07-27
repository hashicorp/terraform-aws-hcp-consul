Kind = "service-router"
Name = "vfrontend"
Routes = [
  {
    Match {
      HTTP {
        Header = [
          {
            Name  = "x-debug"
            Exact = "1"
          },
        ]
      }
    }
    Destination {
      Service       = "frontend"
      ServiceSubset = "v1"
    }
  },
  {
    Match {
      HTTP {
        Header = [
          {
            Name  = "x-debug"
            Exact = "2"
          },
        ]
      }
    }
    Destination {
      Service       = "frontend"
      ServiceSubset = "v2"
    }
  },
  # NOTE: a default catch-all will send unmatched traffic to "web"
]
