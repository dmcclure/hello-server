# Load balancer security group
resource "aws_security_group" "lb" {
  name        = "hello-server-load-balancer-${var.environment}"
  description = "Controls access to the ${var.environment} environment LB"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = "9090"
    to_port     = "9090"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic to the ECS cluster should only come from the LB
resource "aws_security_group" "ecs_tasks" {
  name        = "hello-server-ecs-tasks-${var.environment}"
  description = "Allows inbound access from the ${var.environment} LB only"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol        = "tcp"
    from_port       = "9090"
    to_port         = "9090"
    security_groups = ["${aws_security_group.lb.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}