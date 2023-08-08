resource "aws_alb" "app" {
  name                       = "app"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = false
  drop_invalid_header_fields = true
  subnets = [
    data.terraform_remote_state.network.outputs.subnet_public_a_id,
    data.terraform_remote_state.network.outputs.subnet_public_c_id
  ]
}

resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_alb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "http_80_app" {
  listener_arn = aws_lb_listener.http_80.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
  condition {
    source_ip {
      values = [var.source_ip]
    }
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_security_group" "alb" {
  name        = "alb"
  description = "Allow inbound alb"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    "Name" = "alb"
  }
}

resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  type              = "egress"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
}

resource "aws_lb_target_group" "app" {
  name                 = "app"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = "60"
  proxy_protocol_v2    = false
  vpc_id               = data.terraform_remote_state.network.outputs.vpc_id
  target_type          = "ip"

  health_check {
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}
