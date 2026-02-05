locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Application = var.app_name
    TfEnv       = "common"
  }
}

data "aws_caller_identity" "current" {}

// Shared-GSG -> Grafana -> Keeper Key
data "secretsmanager_login" "keeper" {
  path = "CG_TIwl5Hqor1cTDLCywYA"
}

