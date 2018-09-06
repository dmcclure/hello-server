resource "aws_ecs_cluster" "main" {
  name = "hello-server-${var.environment}"
}

resource "aws_appautoscaling_target" "app" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "ECSServiceAverageCPUUtilization:${var.environment}:${aws_appautoscaling_target.app.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "${aws_appautoscaling_target.app.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.app.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.app.service_namespace}"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}

resource "aws_appautoscaling_policy" "memory_policy" {
  name               = "ECSServiceAverageMemoryUtilization:${var.environment}:${aws_appautoscaling_target.app.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "${aws_appautoscaling_target.app.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.app.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.app.service_namespace}"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 60
  }
}

data "aws_ssm_parameter" "database_dsn" {
  name = "/hello-server/${var.environment}/database_dsn"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "hello-server-task-${var.environment}"
  execution_role_arn       = "${aws_iam_role.ecs_task_execution.arn}"
  task_role_arn            = "${aws_iam_role.ecs_task.arn}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions = <<DEFINITION
[
  {
    "name": "hello-server-${var.environment}",
    "image": "hello-server:${var.environment}",
    "cpu": 256,
    "memory": 512,
    "portMappings": [{
      "hostPort": 9090,
      "protocol": "tcp",
      "containerPort": 9090
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "environment": [{
        "name": "ENV_NAME",
        "value": "${var.environment}"
      },
      {
        "name": "DATABASE_DSN",
        "value": "${data.aws_ssm_parameter.database_dsn.value}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name            = "hello-server-service-${var.environment}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"

  # Create the service with a desired count of 2, but allow external changes to this number.
  # Autoscaling may alter this number, and we don't want this to cause a Terraform plan difference.
  desired_count = 2
  lifecycle {
    ignore_changes = ["desired_count"]
  }

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_tasks.id}"]
    subnets          = ["${aws_subnet.private.*.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.app.id}"
    container_name   = "hello-server-${var.environment}"
    container_port   = "9090"
  }

  depends_on = [
    "aws_lb_listener.app",
    "aws_ecs_task_definition.app"
  ]
}

# Create a task execution IAM role that will allow containers to pull images from ECS and publish logs to CloudWatch
resource "aws_iam_role" "ecs_task_execution" {
  name               = "hello-server-ecs-task-execution-${var.environment}"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = "${aws_iam_role.ecs_task_execution.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create an IAM role that will allow our containers to call AWS APIs (such as accessing DynamoDB or ElastiCache)
resource "aws_iam_role" "ecs_task" {
  name = "hello-server-ecs-task-role-${var.environment}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task" {
  name = "hello-server-ecs-task-role-policy-${var.environment}"
  role = "${aws_iam_role.ecs_task.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
