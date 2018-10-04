# Create an IAM role that will allow CodeBuild to call AWS APIs (such as logging, uploading to S3 and pushing to ECR)
resource "aws_iam_role" "codebuild" {
  name = "hello-server-codebuild-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "codebuild.amazonaws.com"
    }
  }
}
EOF
}

resource "aws_iam_role_policy" "codebuild" {
  name = "hello-server-codebuild-role-policy"
  role = "${aws_iam_role.codebuild.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "s3:CreateBucket",
        "s3:GetObject",
        "s3:List*",
        "s3:PutObject",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ssm:GetParameters"
      ]
    }
  ]
}
EOF
}

resource "aws_ecr_repository" "ecr_repo" {
  name = "hello-server"
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = "${aws_ecr_repository.ecr_repo.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 10,
            "description": "Keep the last 100 images",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 100
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_codebuild_project" "test" {
  name = "hello-server-test"
  description = "Builds a hello-server Docker image for the test environment and uploads it to ECR"
  build_timeout = "30"
  service_role = "${aws_iam_role.codebuild.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/golang:1.10"
    type = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "BRANCH_NAME"
      "value" = "test"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "master" {
  name = "hello-server-master"
  description = "Builds a hello-server Docker image for the staging and production environments and uploads it to ECR"
  build_timeout = "30"
  service_role = "${aws_iam_role.codebuild.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/golang:1.10"
    type = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "BRANCH_NAME"
      "value" = "master"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}
