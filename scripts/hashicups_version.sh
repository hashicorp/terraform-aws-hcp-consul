#!/bin/bash

# https://github.com/hashicorp-demoapp/hashicups-setups/blob/main/docker-compose-deployment/docker-compose.yaml
FRONTEND_VERSION="v1.0.1"
PUBLIC_API_VERSION="v0.0.6"
PRODUCT_API_VERSION="v0.0.20"
PRODUCT_API_DB_VERSION="v0.0.20"
PAYMENT_API_VERSION="v0.0.16"

version () {
  file=$1

  sed -i.bak "s/frontend:v[0-9.]*/frontend:${FRONTEND_VERSION}/" $file
  sed -i.bak "s/public-api:v[0-9.]*/public-api:${PUBLIC_API_VERSION}/" $file
  sed -i.bak "s/product-api:v[0-9.]*/product-api:${PRODUCT_API_VERSION}/" $file
  sed -i.bak "s/product-api-db:v[0-9.]*/product-api-db:${PRODUCT_API_DB_VERSION}/" $file
  sed -i.bak "s/payments:v[0-9.]*/payments:${PAYMENT_API_VERSION}/" $file

  rm -rf $file.bak
}

# ec2
version "modules/hcp-ec2-client/templates/hashicups.nomad"

# eks
for service in frontend payments public-api product-api postgres; do
  version "modules/k8s-demo-app/services/$service.yaml"
done

# ecs
version "modules/hcp-ecs-client/services.tf"
