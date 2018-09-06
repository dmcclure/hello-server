# Create a VPC for our environment
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "hello-server-${var.environment}"
    environment = "${var.environment}"
  }
}
