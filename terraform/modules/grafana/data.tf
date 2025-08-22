locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Application = var.app_name
    TfEnv       = var.env_name
  }
}

data "aws_ssm_parameter" "kms_arn" {
  name = "/${var.app_name}/common/kms_arn"
}

data "aws_ssm_parameter" "kms_id" {
  name = "/${var.app_name}/common/kms_id"
}

// Shared-GSG -> Grafana -> rds
data "secretsmanager_login" "db" {
  path = "yUO3Wbl52b8g9LukZgZ5uA"
}

// Shared-GSG -> Grafana -> Loki -> BasicAuth
data "secretsmanager_login" "loki_basic" {
  path = "TVNsnRso_U7J_raing91Dw"
}

// Shared-GSG -> Grafana -> Prometheus -> BasicAuth
data "secretsmanager_login" "prometheus_basic" {
  path = "9edLxyQsbIoU5lw7K3m36w"
}
