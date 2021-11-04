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

### Deployment

1. Initialize and apply the Terraform configuration

```
terraform init && terraform apply
```

### Accessing the Deployment

#### HCP Consul

The HCP Consul cluster can be accessed via the outputs `consul_url` and
`consul_root_token`.

#### Nomad 

This example is running on nomad, which can be accessed via the outputs `nomad_url` with the username `nomad` and `consul_root_token`.

#### EC2 instances

**Warning**: This instance, by default, is publicly accessible on port 8080 and 8081,
make sure to delete it when done.

The EC2 applications be accessed via the `hashicups_url` output, providing URL to the demo app.
