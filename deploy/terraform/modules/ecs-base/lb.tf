resource "aws_alb_target_group" "main" {
  name                 = local.full_environment_prefix
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 30
  target_type          = "ip"

  health_check {
    path                = "/"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 20
    matcher             = "200-399"
  }
}

resource "aws_alb" "main" {
  name            = local.full_environment_prefix
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.lb_sg.id]
}

resource "aws_alb_listener" "front_end_ssl" {
  load_balancer_arn = aws_alb.main.id

  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2015-05"
  certificate_arn = aws_acm_certificate_validation.default.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}

## No SSL
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id

  port     = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_security_group" "lb_sg" {
  description = "controls access to the application ELB"

  vpc_id      = module.vpc.vpc_id
  name_prefix = local.full_environment_prefix

  lifecycle {
    ignore_changes = [ingress]
  }
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}