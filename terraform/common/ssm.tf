resource "aws_ssm_parameter" "ksm_config" {
  name   = "/${var.app_name}/common/ksm_config"
  value  = data.secretsmanager_login.keeper.password
  type   = "SecureString"
  key_id = aws_kms_key.common.arn
}

resource "aws_ssm_parameter" "kms_arn" {
  name  = "/${var.app_name}/common/kms_arn"
  value = aws_kms_key.common.arn
  type  = "String"
}

resource "aws_ssm_parameter" "kms_id" {
  name  = "/${var.app_name}/common/kms_id"
  value = aws_kms_key.common.key_id
  type  = "String"
}
