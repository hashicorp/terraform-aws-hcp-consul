output "dashboard_id" {
  value = aws_instance.consul_client_dashboard[0].id
}

output "counting_id" {
  value = aws_instance.consul_client_counting[0].id
}

output "dashboard_url" {
  value = "http://${aws_instance.consul_client_dashboard[0].public_ip}:8080"
}

output "counting_url" {
  value = "http://${aws_instance.consul_client_counting[0].public_ip}:8080"
}
