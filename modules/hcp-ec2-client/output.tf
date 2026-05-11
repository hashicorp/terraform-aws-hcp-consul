# Copyright IBM Corp. 2021, 2026
# SPDX-License-Identifier: MPL-2.0

output "host_id" {
  value = aws_instance.host.id
}

output "public_ip" {
  value = aws_instance.host.public_ip
}
