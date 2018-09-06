terraform {
  backend "s3" {
    bucket = "hello-server-terraform-artifacts"
    key    = "hello-server/terraform.tfstate"
    region = "us-east-1"
  }

  provider "aws" {
    version = "~> 1.32.0"
    shared_credentials_file = "$HOME/.aws/credentials"
    profile = "default"
    region = "${var.aws_region}"
  }
}

# These values are used when creating the subnets of each environment.
# Each environment has public and private subnets in different availability zones.
# The offset is used to calculate the third octet of each subnet's CIDR block.
# For example, if there are three availability zones, the subnets would look like this:
#  - Test environment:
#     - Private subnets: 10.0.0.0/24, 10.0.1.0/24 and 10.0.2.0/24
#     - Public subnets: 10.0.3.0/24, 10.0.4.0/24 and 10.0.5.0/24
#  - Staging environment:
#     - Private subnets: 10.0.32.0/24, 10.0.33.0/24 and 10.0.34.0/24
#     - Public subnets: 10.0.35.0/24, 10.0.36.0/24 and 10.0.37.0/24
#  - Test environment:
#     - Private subnets: 10.0.64.0/24, 10.0.65.0/24 and 10.0.66.0/24
#     - Public subnets: 10.0.67.0/24, 10.0.68.0/24 and 10.0.69.0/24
locals {
  subnet_offsets = {
    test       = 0
    staging    = 32
    production = 64
  }
}