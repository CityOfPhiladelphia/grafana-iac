// RDS security group
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.env_name}-rds"
  description = "SG for RDS"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}-rds" })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id = aws_security_group.rds.id

  description                  = "RDS inbound access from EC2 security group"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.ec2.id
}

// EC2 security group
resource "aws_security_group" "ec2" {
  name        = "${var.app_name}-${var.env_name}-ec2"
  description = "SG for EC2"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}-ec2" })
}

resource "aws_vpc_security_group_egress_rule" "ec2_outbound_all_to_everywhere" {
  security_group_id = aws_security_group.ec2.id
  description       = "Full outbound access"

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_inbound_http_from_alb" {
  security_group_id = aws_security_group.ec2.id
  description       = "Inbound http access from ALB"

  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_inbound_loki_from_alb" {
  security_group_id = aws_security_group.ec2.id
  description       = "Inbound loki access from ALB"

  ip_protocol                  = "tcp"
  from_port                    = 3100
  to_port                      = 3100
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_inbound_prometheus_from_alb" {
  security_group_id = aws_security_group.ec2.id
  description       = "Inbound prometheus access from ALB"

  ip_protocol                  = "tcp"
  from_port                    = 9090
  to_port                      = 9090
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_inbound_mimir_from_ec2" {
  security_group_id = aws_security_group.ec2.id
  description       = "Inbound mimir access from other ec2"

  ip_protocol                  = "tcp"
  from_port                    = 9095
  to_port                      = 9095
  referenced_security_group_id = aws_security_group.ec2.id
}

// ALB security group
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.env_name}-alb"
  description = "SG for ALB"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_inbound_https_from_anywhere" {
  security_group_id = aws_security_group.alb.id
  description       = "Inbound https access from anywhere"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_inbound_http_from_anywhere" {
  security_group_id = aws_security_group.alb.id
  description       = "Inbound http access from anywhere"

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_inbound_loki_from_cidr" {
  for_each          = var.monitoring_source_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "Inbound Loki access from ${each.value.name}"

  ip_protocol = "tcp"
  from_port   = 3100
  to_port     = 3100
  cidr_ipv4   = each.value.cidr
}

resource "aws_vpc_security_group_ingress_rule" "alb_inbound_prometheus_from_cidr" {
  for_each          = var.monitoring_source_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "Inbound Prometheus access from ${each.value.name}"

  ip_protocol = "tcp"
  from_port   = 9090
  to_port     = 9090
  cidr_ipv4   = each.value.cidr
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound_all_to_ec2" {
  security_group_id = aws_security_group.alb.id
  description       = "Full outbound access to ec2"

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.ec2.id
}
