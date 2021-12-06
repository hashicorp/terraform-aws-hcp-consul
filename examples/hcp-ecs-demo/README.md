# hcp-ecs-demo

This example creates all of the AWS and HCP resources necessary for connecting a
HCP Consul cluster to a Consul client on ECS.

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

2. Go to your HCP Consul Cluster and create an allow all intention.

### Accessing the Deployment

#### HCP Consul

The HCP Consul cluster can be accessed via the outputs `consul_url` and
`consul_root_token`.

#### Hashicups

The ECS application be accessed via the `hashicups_url` output, providing URL to the demo app.
