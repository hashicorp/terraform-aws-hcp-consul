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
  name = "product_api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public_api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_product_db" {
  name = "product_db"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "product_api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_payment_api" {
  name = "payment_api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public_api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}
