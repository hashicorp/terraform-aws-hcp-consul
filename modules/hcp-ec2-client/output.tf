output "host_id" {
  value = aws_instance.host.id
}

output "public_ip" {
  value = aws_instance.host.public_ip
}
