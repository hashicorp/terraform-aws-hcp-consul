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

### Deployment

1. Initialize and apply the Terraform configuration

```
terraform init && terraform apply
```

### Accessing the Deployment

#### HCP Consul

The HCP Consul cluster can be accessed via the outputs `consul_url` and
`consul_root_token`.

#### EKS Cluster

The EKS cluster can be accessed via the output `kubeconfig_filename`, which
references a created kubeconfig file that can be used by setting the
`KUBECONFIG` environment variable

#### Demo Application

**Warning**: This application is publicly accessible, make sure to delete the Kubernetes
resources associated to the application when done.

The demo application can be accessed via the output `dashboard_url`.

An Ingress Gateway is setup to forward traffic to the `dashboard` service, with
the correct Consul intentions. However, the `dashboard` service does not have
the correct intentions setup to communicate with the `couting` service.
