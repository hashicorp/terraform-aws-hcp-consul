output "host_id" {
  value = aws_instance.nomad_host[0].id
}

output "public_ip" {
  value = aws_instance.nomad_host[0].public_ip
}
