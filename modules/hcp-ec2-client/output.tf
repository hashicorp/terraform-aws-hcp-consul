output "host_id" {
  value = aws_instance.nomad_host[0].id
}

output "host_dns" {
  value = aws_instance.nomad_host[0].public_dns
}
