# HCP Consul on AWS Module

Terraform module for connecting a HashiCorp Cloud Platform (HCP) Consul cluster to AWS.

## Usage

This module connects a HashiCorp Virtual Network (HVN) with an AWS VPC, ensuring
that all networking rules are in place to allow a Consul client to communicate
with the HCP Consul servers. The module accomplishes this in four steps:

1. Create and accept a peering connection between the HVN and VPC
2. Create HVN routes that will direct HCP traffic to the CIDR ranges of the
   subnets.
3. Create AWS routes for each AWS route table that will direct traffic to the
   HVN's own CIDR range.
4. Create AWS ingress rules necessary for HCP Consul to communicate to Consul
   clients.

```hcl
module "aws_hcp_consul" {
  source = "hashicorp/hcp-consul/aws"

  hvn             = hcp_hvn.main
  vpc_id          = "vpc-0daa4a0915f1857db"
  subnet_ids      = ["subnet-098e9eb4bdd582522", "subnet-198e9eb4bdd582522"]
  route_table_ids = ["rtb-079170034b7a99118", "rtb-179170034b7a99118"]

  # Optionally provide security_group_ids. A new security group will be created
  # if none are provided.
  security_group_ids = ["sg-0ba8d296a786e93c7"]
}
```

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

To support these examples, a few submodules are provided as useful utilities,
for learning and experimentation purposes.

- [hcp-ec2-client](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/modules/hcp-ec2-client) - [**For Testing Only**]: installs Consul and runs Consul clients with EC2 virtual machines.
- [hcp-eks-client](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/modules/hcp-eks-client) - [**For Testing Only**]: installs the [Consul Helm chart](https://www.consul.io/docs/k8s/helm) on the provided Kubernetes cluster.
- [k8s-demo-app](https://github.com/hashicorp/terraform-aws-hcp-consul/tree/main/modules/k8s-demo-app) - [**For Testing Only**]: installs a demo application onto the Kubernetes cluster, using the Consul service mesh.

## License

This code is released under the Mozilla Public License 2.0. Please see [LICENSE](https://github.com/hashicorp/terraform-aws-hcp-consul/blob/main/LICENSE) for more details.
