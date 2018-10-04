resource "aws_iam_role" "codepipeline_role" {
  name = "hello-server-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "hello-server-codepipeline-policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject",
        "iam:PassRole",
        "codepipeline:*",
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision",
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ],
  "Version": "2012-10-17"
}
EOF
}

data "aws_ssm_parameter" "github_token" {
  name = "/hello-server/github_token"
}

resource "aws_s3_bucket" "codepipeline_artifacts_test" {
    bucket = "hello-server-codepipeline-artifacts-test"
    acl    = "private"
}

resource "aws_codepipeline" "test" {
  name = "hello-server-test"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_artifacts_test.bucket}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "github-checkout"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        OAuthToken = "${data.aws_ssm_parameter.github_token.value}"
        Owner      = "dmcclure"
        Repo       = "hello-server"
        Branch     = "test"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "build-and-test"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["image-definition"]
      version          = "1"

      configuration {
        ProjectName = "hello-server-test"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["image-definition"]
      version         = "1"

      configuration {
        ClusterName = "hello-server-test"
        ServiceName = "hello-server-test"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_artifacts_master" {
    bucket = "hello-server-codepipeline-artifacts-master"
    acl    = "private"
}

resource "aws_codepipeline" "master" {
  name = "hello-server-master"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_artifacts_master.bucket}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "github-checkout"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        OAuthToken = "${data.aws_ssm_parameter.github_token.value}"
        Owner      = "dmcclure"
        Repo       = "hello-server"
        Branch     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "build-and-test"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["image-definition"]
      version          = "1"

      configuration {
        ProjectName = "hello-server-master"
      }
    }
  }

  stage {
    name = "Staging-Deploy"

    action {
      name            = "deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["image-definition"]
      version         = "1"

      configuration {
        ClusterName = "hello-server-staging"
        ServiceName = "hello-server-staging"
        FileName    = "imagedefinitions.json"
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name            = "approval"
      category        = "Approval"
      owner           = "AWS"
      provider        = "Manual"
      version         = "1"

      configuration {
        # "NotificationArn": "arn:aws:sns:us-west-2:80398EXAMPLE:MyApprovalTopic"
      }
    }
  }

  stage {
    name = "Production-Deploy"

    action {
      name            = "deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["image-definition"]
      version         = "1"

      configuration {
        ClusterName = "hello-server-production"
        ServiceName = "hello-server-production"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}