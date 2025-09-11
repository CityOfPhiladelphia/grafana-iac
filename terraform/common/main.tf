terraform {
  required_version = "~> 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  cloud {
    organization = "Philadelphia"

    workspaces {
      name = "grafana-common"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
