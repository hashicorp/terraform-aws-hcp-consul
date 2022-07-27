Kind = "service-splitter"
Name = "frontend"
Splits = [
  {
    Weight        = 70
    ServiceSubset = "v1"
  },
  {
    Weight        = 30
    ServiceSubset = "v2"
  },
]
