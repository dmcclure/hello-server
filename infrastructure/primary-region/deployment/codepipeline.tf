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
                "codebuild:StartBuild"
            ],
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

resource "aws_s3_bucket" "codepipeline_artifacts" {
    bucket = "hello-server-codepipeline-artifacts"
    acl    = "private"
}

resource "aws_codepipeline" "test" {
  name     = "hello-server-test"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_artifacts.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "github-checkout"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source-test"]

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
      name             = "build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source-test"]
      output_artifacts = ["build-output-test"]
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
      provider        = "CodeDeploy"
      input_artifacts = ["build-output-test"]
      version         = "1"

      configuration {
        ApplicationName     = "hello-server-test"
        DeploymentGroupName = "hello-server-test"
        # ApplicationName     = "${data.terraform_remote_state.codedeploy.application-name}"
        # DeploymentGroupName = "${data.terraform_remote_state.codedeploy.deployment-group-name}"
      }
    }
  }
}