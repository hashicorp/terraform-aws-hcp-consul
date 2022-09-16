resource "consul_config_entry" "service_intentions_deny" {
  name = "*"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "*"
        Action = "deny"
      }
    ]
  })
  depends_on = [
    aws_instance.host
  ]
}

resource "consul_config_entry" "service_intentions_product_api" {
  name = "product-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
  depends_on = [
    aws_instance.host
  ]
}
resource "consul_config_entry" "service_intentions_frontend_publicapi" {
  name = "public-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "frontend"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
  depends_on = [
    aws_instance.host
  ]
}

resource "consul_config_entry" "service_intentions_ingress_frontend" {
  name = "frontend"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "hashicups-ingress"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
  depends_on = [
    aws_instance.host
  ]
}

resource "consul_config_entry" "service_intentions_product_db" {
  name = "product-db"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "product-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
  depends_on = [
    aws_instance.host
  ]
}

resource "consul_config_entry" "service_intentions_payment_api" {
  name = "payment-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
  depends_on = [
    aws_instance.host
  ]
}
