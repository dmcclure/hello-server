resource "aws_lb" "app" {
  name            = "hello-server-${var.environment}"
  load_balancer_type = "application"
  subnets         = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.lb.id}"]
}

resource "aws_lb_target_group" "app" {
  name        = "hello-server-${var.environment}"
  port        = "9090"
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/health"
    unhealthy_threshold = "2"
  }
}

# Redirect all traffic from the LB to the target group
resource "aws_lb_listener" "app" {
  load_balancer_arn = "${aws_lb.app.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.app.id}"
    type             = "forward"
  }
}