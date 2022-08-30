Kind = "service-splitter"
Name = "frontend"
Splits = [
  {
    Weight        = 50
    ServiceSubset = "v1"
  },
  {
    Weight        = 50
    ServiceSubset = "v2"
  },
]