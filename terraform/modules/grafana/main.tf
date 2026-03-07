terraform {
  required_version = "~> 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.32.0"
    }
    secretsmanager = {
      source  = "keeper-security/secretsmanager"
      version = "1.1.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
  }
}

