terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.15.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "hcp" {
  client_id = "SPA8Uqgs7GvDSIttzDsJLZbW9KVgSWbK"
  client_secret = "8qoE80dp_mTjuCY8YBh2s8kiE4kHdJK9RzBP0WLdMyrkLXpq9-PCAodMcMfS-LHX"
}
