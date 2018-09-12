# Set up cloudwatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "app" {
  name              = "hello-server-${var.environment}"
  retention_in_days = 30
}