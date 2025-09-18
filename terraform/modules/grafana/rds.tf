resource "aws_db_subnet_group" "postgres" {
  name       = "${var.app_name}-${var.env_name}"
  subnet_ids = var.db_subnet_ids

  tags = local.default_tags
}

resource "aws_db_instance" "postgres" {
  identifier                 = "${var.app_name}-${var.env_name}"
  allocated_storage          = 20
  storage_type               = "gp3"
  engine                     = "postgres"
  engine_version             = "17.4"
  backup_retention_period    = 7
  db_subnet_group_name       = aws_db_subnet_group.postgres.name
  db_name                    = "postgres"
  username                   = data.secretsmanager_login.db.login
  password                   = data.secretsmanager_login.db.password
  apply_immediately          = true
  auto_minor_version_upgrade = false
  storage_encrypted          = true
  kms_key_id                 = data.aws_ssm_parameter.kms_arn.value
  deletion_protection        = !var.dev_mode
  skip_final_snapshot        = var.dev_mode
  instance_class             = "db.t4g.micro"
  vpc_security_group_ids     = [aws_security_group.rds.id]

  tags = local.default_tags
}
