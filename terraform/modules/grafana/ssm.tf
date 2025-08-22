resource "aws_ssm_parameter" "rds_pw" {
  name   = "/${var.app_name}/${var.env_name}/rds_pw"
  value  = data.secretsmanager_login.db.password
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "rds_user" {
  name   = "/${var.app_name}/${var.env_name}/rds_user"
  value  = data.secretsmanager_login.db.login
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "loki_pw" {
  name   = "/${var.app_name}/${var.env_name}/loki_pw"
  value  = data.secretsmanager_login.loki_basic.password
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "loki_user" {
  name   = "/${var.app_name}/${var.env_name}/loki_user"
  value  = data.secretsmanager_login.loki_basic.login
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "prometheus_pw" {
  name   = "/${var.app_name}/${var.env_name}/prometheus_pw"
  value  = data.secretsmanager_login.prometheus_basic.password
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "prometheus_user" {
  name   = "/${var.app_name}/${var.env_name}/prometheus_user"
  value  = data.secretsmanager_login.prometheus_basic.login
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "rds_host" {
  name  = "/${var.app_name}/${var.env_name}/rds_host"
  value = aws_db_instance.postgres.endpoint
  type  = "String"
}

resource "aws_ssm_parameter" "rds_db_name" {
  name  = "/${var.app_name}/${var.env_name}/rds_db_name"
  value = aws_db_instance.postgres.db_name
  type  = "String"
}

resource "aws_ssm_parameter" "grafana_s3_name" {
  name  = "/${var.app_name}/${var.env_name}/grafana_s3_name"
  value = aws_s3_bucket.main.bucket
  type  = "String"
}
