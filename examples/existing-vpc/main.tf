terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.10.0"

  name                 = "existing-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_ids
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_ids
}

output "public_subnet1" {
  value = module.vpc.public_subnets[0]
}

output "public_subnet2" {
  value = module.vpc.public_subnets[1]
}

output "private_subnet1" {
  value = module.vpc.private_subnets[0]
}

output "private_subnet2" {
  value = module.vpc.private_subnets[1]
}
