Kind = "service-splitter"
Name = "frontend"
Splits = [
  {
    Weight        = 0
    ServiceSubset = "v1"
  },
  {
    Weight        = 100
    ServiceSubset = "v2"
  },
]