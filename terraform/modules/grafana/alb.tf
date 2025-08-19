resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.env_name}"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.alb_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = !var.dev_mode
  tags                       = local.default_tags
}
