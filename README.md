# HCP Consul on AWS Module

Terraform module for connecting a HashiCorp Cloud Platform (HCP) Consul cluster to AWS.

## Examples

A number of examples are provided which will run the following setup:

1. Create an AWS VPC and associated resources
2. Create a HashiCorp Virtual Network (HVN)
3. Peer the AWS VPC with the HVN
4. Create a HCP Consul cluster
5. Run Consul clients within the provisioned AWS VPC
6. Run a demo application on the chosen AWS runtime

These examples allow you to easily research and demo HCP Consul.

- [hcp-ec2-demo](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/examples/hcp-ec2-demo) - Use EC2 virtual machines to run Consul clients.
- [hcp-eks-demo](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/examples/hcp-eks-demo) - Provision and use an EKS cluster to run Consul clients.

## Submodules

To support these examples, a few submodules are provided as useful utilities.

- [hcp-ec2-client](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/modules/hcp-ec2-client) - installs Consul and runs Consul clients with EC2 virtual machines.
- [hcp-eks-client](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/modules/hcp-eks-client) - installs the [Consul Helm chart](https://www.consul.io/docs/k8s/helm) on the provided Kubernetes cluster.
- [k8s-demo-app](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/modules/k8s-demo-app) - installs a demo application onto the Kubernetes cluster, using the Consul service mesh.

## License

This code is released under the Mozilla Public License 2.0. Please see [LICENSE](https://github.com/hashicorp/terraform-aws-hcp-consul/blob/main/LICENSE) for more details.
