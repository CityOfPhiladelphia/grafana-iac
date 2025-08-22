resource "aws_lb_target_group" "grafana" {
  name        = "${var.app_name}-${var.env_name}-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  # Grafana doesn't have many long running requests so 1 minute should be enough
  deregistration_delay = 60

  health_check {
    enabled = true
    path    = "/api/health"
  }
}

resource "aws_autoscaling_attachment" "grafana" {
  autoscaling_group_name = aws_autoscaling_group.main.id
  lb_target_group_arn    = aws_lb_target_group.grafana.arn
}

resource "aws_lb_target_group" "loki" {
  name        = "${var.app_name}-${var.env_name}-loki"
  port        = 3100
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  # Grafana doesn't have many long running requests so 1 minute should be enough
  deregistration_delay = 60

  health_check {
    enabled = true
    path    = "/ready"
  }
}

resource "aws_autoscaling_attachment" "loki" {
  autoscaling_group_name = aws_autoscaling_group.main.id
  lb_target_group_arn    = aws_lb_target_group.loki.arn
}

resource "aws_lb_target_group" "prometheus" {
  name        = "${var.app_name}-${var.env_name}-prometheus"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  # Grafana doesn't have many long running requests so 1 minute should be enough
  deregistration_delay = 60

  health_check {
    enabled = true
    path    = "/-/health"
  }
}

resource "aws_autoscaling_attachment" "prometheus" {
  autoscaling_group_name = aws_autoscaling_group.main.id
  lb_target_group_arn    = aws_lb_target_group.prometheus.arn
}

resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.env_name}"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.alb_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = !var.dev_mode
  tags                       = local.default_tags
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_lb_listener" "loki" {
  load_balancer_arn = aws_lb.main.arn
  port              = "3100"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki.arn
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = aws_lb.main.arn
  port              = "9090"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }
}
