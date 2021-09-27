# hcp-ec2-demo

This example creates all of the AWS and HCP resources necessary for connecting a
HCP Consul cluster to a Consul client on EC2.

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