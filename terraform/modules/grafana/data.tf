locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Application = "Grafana"
    TfEnv       = var.env_name
  }
}

data "aws_ssm_parameter" "kms_arn" {
  name = "/grafana/common/kms_arn"
}

data "aws_ssm_parameter" "kms_id" {
  name = "/grafana/common/kms_id"
}

// Shared-GSG -> Grafana -> rds
data "secretsmanager_login" "db" {
  path = "yUO3Wbl52b8g9LukZgZ5uA"
}
