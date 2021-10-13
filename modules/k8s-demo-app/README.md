## k8s-demo-app

A Terraform module used to install a demo application for HCP Consul.

This module will install two services, `dashboard` and `counting`, along with
their associated deployments, service accounts, etc. Alongside, it will use
Consul CRDs to configure an ingress gateway to expose the `dashboard` service.
