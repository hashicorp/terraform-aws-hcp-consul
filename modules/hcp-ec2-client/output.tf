output "ssh_private_key" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "client_public_ips" {
  value = [for c in aws_instance.consul_client : c.public_ip]
}
