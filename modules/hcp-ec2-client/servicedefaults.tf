# this is needed as their will be a tutorial on blue green deployment 
# and i just want to show the functionality to make it happen and 
# hide some of the complexity like service defaults

resource "consul_config_entry" "service_default_frontend" {
  name = "frontend"
  kind = "service-defaults"

  config_json = jsonencode({
    Protocol = "http"
  })
}
