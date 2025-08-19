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
