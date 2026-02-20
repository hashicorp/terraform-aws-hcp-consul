# Copyright IBM Corp. 2021, 2023
# SPDX-License-Identifier: MPL-2.0

output "hashicups_url" {
  value = aws_lb.ingress.dns_name
}
