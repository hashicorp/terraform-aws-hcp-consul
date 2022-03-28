resource "aws_lb" "ingress" {
  name               = "${local.secret_prefix}-ingress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "frontend" {
  name                 = "${local.secret_prefix}-frontend"
  port                 = local.frontend_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 10
}

resource "aws_lb_target_group" "public-api" {
  name                 = "${local.secret_prefix}-api"
  port                 = local.public_api_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 10
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = local.lb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "public-api" {
  listener_arn = aws_lb_listener.frontend.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public-api.arn
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}
