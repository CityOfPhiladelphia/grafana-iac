data "aws_caller_identity" "current" {}

resource "aws_kms_key" "grafana" {
  description = "grafana"
  key_usage   = "ENCRYPT_DECRYPT"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_kms_alias" "grafana" {
  name          = "alias/grafana"
  target_key_id = aws_kms_key.grafana.key_id
}

resource "aws_ssm_parameter" "kms_arn" {
  name  = "/grafana/common/kms_arn"
  value = aws_kms_key.grafana.arn
  type  = "String"
}

resource "aws_ssm_parameter" "kms_id" {
  name  = "/grafana/common/kms_id"
  value = aws_kms_key.grafana.key_id
  type  = "String"
}
