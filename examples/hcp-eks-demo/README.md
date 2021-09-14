## HCP EKS Demo

This Terraform example stands up a full deployment of a HCP Consul cluster
connected to an AWS EKS cluster.

### Prerequisites

1. Create a HCP Service Key and set the required environment variables

```
export HCP_CLIENT_ID=...
export HCP_CLIENT_SECRET=...
```

2. Export your AWS Account credentials, as defined by the AWS Terraform provider

3. Initialize and apply the Terraform configuration

```
terraform init && terraform apply
```

4. The provisioned Consul cluster can be accessed via the outputs `consul_url`
   and `consul_root_token`

5. The provisioned EKS cluster can be accessed via the output
   `kubeconfig_filename`, which references a created kubeconfig file that can be
   used by setting the `KUBECONFIG` environment variable
