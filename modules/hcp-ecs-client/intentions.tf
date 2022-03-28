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
}
