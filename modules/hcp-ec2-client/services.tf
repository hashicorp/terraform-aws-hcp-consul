# This is needed for a tutorial on blue green deployments.
# This helps show the functionality to make it happen and 
# hide some of the complexity like service defaults
resource "consul_config_entry" "service_default_frontend" {
  name = "frontend"
  kind = "service-defaults"

  config_json = jsonencode({
    Protocol = "http"
  })

  depends_on = [time_sleep.wait_for_startup]
}
