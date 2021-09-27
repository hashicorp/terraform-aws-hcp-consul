output "dashboard_id" {
  value = aws_instance.consul_client_dashboard[0].id
}
output "counting_id" {
  value = aws_instance.consul_client_counting[0].id
}
