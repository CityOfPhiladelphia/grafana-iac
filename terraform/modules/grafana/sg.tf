resource "aws_security_group" "eks_control" {
  name        = "${var.app_name}-${var.env_name}-eks-control"
  description = "SG for EKS control plane"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, {
    Name = "${var.app_name}-${var.env_name}-eks-control"
  })
}

resource "aws_vpc_security_group_ingress_rule" "eks_control_https_from_phl" {
  security_group_id = aws_security_group.eks_control.id

  description = "HTTPS inbound access from PHL"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "10.0.0.0/8"
}

resource "aws_vpc_security_group_ingress_rule" "eks_control_all_from_node" {
  security_group_id = aws_security_group.eks_control.id

  description                  = "All access internally"
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.eks_node.id
}


resource "aws_vpc_security_group_egress_rule" "eks_control_all_to_outbound" {
  security_group_id = aws_security_group.eks_control.id

  description = "All access outbound"
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_security_group" "eks_node" {
  name        = "${var.app_name}-${var.env_name}-eks-node"
  description = "SG for EKS node group"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, {
    Name                                                     = "${var.app_name}-${var.env_name}-eks"
    "karpenter.sh/discovery-${var.app_name}-${var.env_name}" = "yes"
  })
}

resource "aws_vpc_security_group_ingress_rule" "eks_node_all_from_control" {
  security_group_id = aws_security_group.eks_node.id

  description                  = "All access internally"
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.eks_control.id
}

#resource "aws_vpc_security_group_ingress_rule" "eks_node_http_from_anywhere" {
#  security_group_id = aws_security_group.eks_node.id
#
#  ip_protocol = "tcp"
#  from_port   = 80
#  to_port     = 80
#  cidr_ipv4   = "0.0.0.0/0"
#}

resource "aws_vpc_security_group_ingress_rule" "eks_node_all_from_self" {
  security_group_id = aws_security_group.eks_node.id

  description                  = "All access internally"
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.eks_node.id
}

#resource "aws_vpc_security_group_ingress_rule" "eks_node_inbound_http_from_alb" {
#  security_group_id = aws_security_group.eks_node.id
#  description       = "Inbound http access from ALB"
#
#  ip_protocol                  = "tcp"
#  from_port                    = 80
#  to_port                      = 80
#  referenced_security_group_id = aws_security_group.alb.id
#}

resource "aws_vpc_security_group_ingress_rule" "eks_node_inbound_grafana_from_alb" {
  security_group_id = aws_security_group.eks_node.id
  description       = "Inbound grafana web ui access from ALB"

  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
  referenced_security_group_id = aws_security_group.alb.id
}
#
resource "aws_vpc_security_group_ingress_rule" "eks_node_inbound_gateway_from_alb" {
  security_group_id = aws_security_group.eks_node.id
  description       = "Inbound loki/mimir access from ALB"

  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.alb.id
}
#
#resource "aws_vpc_security_group_ingress_rule" "eks_node_inbound_prometheus_from_alb" {
#  security_group_id = aws_security_group.eks_node.id
#  description       = "Inbound prometheus access from ALB"
#
#  ip_protocol                  = "tcp"
#  from_port                    = 9090
#  to_port                      = 9090
#  referenced_security_group_id = aws_security_group.alb.id
#}

# The default cluster security group is applied to fargate
resource "aws_vpc_security_group_ingress_rule" "eks_default_sg_all_from_node" {
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  description                  = "All access from nodes"
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.eks_node.id
}

resource "aws_vpc_security_group_egress_rule" "eks_node_all_to_outbound" {
  security_group_id = aws_security_group.eks_node.id

  description = "All access outbound"
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}

// Kafka security group
resource "aws_security_group" "kafka" {
  name        = "${var.app_name}-${var.env_name}-kafka"
  description = "SG for Kafka"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}-kafka" })
}

resource "aws_vpc_security_group_ingress_rule" "kafka_from_eks" {
  security_group_id = aws_security_group.kafka.id

  description                  = "Kafka inbound access from EKS node group"
  ip_protocol                  = "tcp"
  from_port                    = 9094
  to_port                      = 9094
  referenced_security_group_id = aws_security_group.eks_node.id
}

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

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id = aws_security_group.rds.id

  description                  = "RDS inbound access from EKS node group"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.eks_node.id
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

resource "aws_vpc_security_group_egress_rule" "alb_all_to_outbound" {
  security_group_id = aws_security_group.alb.id

  description = "All access outbound"
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}
