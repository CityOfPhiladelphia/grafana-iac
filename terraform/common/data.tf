locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Application = var.app_name
    TfEnv       = "common"
  }
}

data "aws_caller_identity" "current" {}

// Shared-GSG -> Github -> Keepercfg
data "secretsmanager_login" "keeper" {
  path = "l4pqeAaAA7HGzEXaNdKVWQ"
}

