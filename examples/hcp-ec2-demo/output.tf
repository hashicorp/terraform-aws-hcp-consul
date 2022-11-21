output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "consul_url" {
  value = hcp_consul_cluster.main.public_endpoint ? (
    hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

output "nomad_url" {
  value = "http://${module.aws_ec2_consul_client.public_ip}:8081"
}

output "hashicups_url" {
  value = "http://${module.aws_ec2_consul_client.public_ip}"
}

output "next_steps" {
  value = local.install_demo_app ? "HashiCups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token." : null
}

output "howto_connect" {
  value = <<EOF
  ${var.install_demo_app ? "The demo app, HashiCups, is installed on a Nomad server we have deployed for you." : ""}
  ${var.install_demo_app ? "To access Nomad using your local client run the following command:" : ""}
  ${var.install_demo_app ? "export NOMAD_HTTP_AUTH=nomad:$(terraform output consul_root_token)" : ""}
  ${var.install_demo_app ? "export NOMAD_ADDR=http://${module.aws_ec2_consul_client.public_ip}:8081" : ""}

  To access Consul from your local client run:
  export CONSUL_HTTP_ADDR="${hcp_consul_cluster.main.consul_public_endpoint_url}"
  export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token)
  
  To connect to the ec2 instance deployed: 
${var.ssh ? "  - To access via SSH run: ssh -i ${abspath(local_file.ssh_key[0].filename)} ubuntu@${module.aws_ec2_consul_client.public_ip}" : ""}
${var.ssm ? "  - To access via SSM run: aws ssm start-session --target ${module.aws_ec2_consul_client.host_id} --region ${local.vpc_region}" : ""}
  EOF
}
