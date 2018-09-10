# IMPORTANT: Make sure the value of backend.key below matches the environment (test, staging or production)
terraform {
  backend "s3" {
    bucket = "hello-server-terraform-artifacts"
    key    = "test/terraform.tfstate"
    region = "us-west-2"
  }

  provider "aws" {
    version = "~> 1.35"
    shared_credentials_file = "$HOME/.aws/credentials"
    profile = "default"
    region = "${var.aws_region}"
  }
}
