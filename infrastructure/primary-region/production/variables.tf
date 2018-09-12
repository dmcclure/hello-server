variable "aws_region" {
  description = "The region where AWS operations will take place"
  default     = "us-west-2"
}

variable "az_count" {
  description = "Maximum number of AZs to cover in a given region"
  default     = "2"
}

variable "environment" {
    description = "Should be 'test', 'staging' or 'production'"
}