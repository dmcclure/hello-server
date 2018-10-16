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

resource "aws_s3_bucket" "codepipeline_artifacts_test_auto" {
  bucket = "hello-server-codepipeline-artifacts-test-auto"
  acl    = "private"
}

# This CodePipeline will automatically deploy code pushed to a "test" branch to the test environment
resource "aws_codepipeline" "test_auto" {
  name = "hello-server-test-auto"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_artifacts_test_auto.bucket}"
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

resource "aws_s3_bucket" "codepipeline_artifacts_test_manual" {
  bucket = "hello-server-codepipeline-artifacts-test-manual"
  acl    = "private"
}

# Writing an ECR image tag to this bucket will trigger the hello-server-test-manual CodePipeline.
# An imagedefinitions.json file containing the image definition needs to be zipped into
# imagedefinitions.zip and uploaded to the bucket. The imagedefinitions.json file's contents should
# look like:
# [{"name":"hello-server","imageUri":"960785399995.dkr.ecr.us-west-2.amazonaws.com/hello-server:test-8cac639"}]
resource "aws_s3_bucket" "codepipeline_test_manual" {
  bucket = "hello-server-test-trigger-manual-build"
  acl    = "private"

  versioning {
    enabled = true
  }
}

# This CodePipeline is used to push a particular existing ECR image to the test cluster.
# It is triggered when an ECR image definition is written to image-to-deploy.zip in the
# "hello-server-codepipeline-test-manual" S3 bucket.
resource "aws_codepipeline" "test_manual" {
  name = "hello-server-test-manual"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_artifacts_test_manual.bucket}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "s3-bucket-updated"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["image-definition"]

      configuration {
        S3Bucket             = "${aws_s3_bucket.codepipeline_test_manual.bucket}"
        PollForSourceChanges = "false"
        S3ObjectKey          = "imagedefinitions.zip"
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

# This CodePipeline will automatically deploy code pushed to a "master" branch to the staging environment.
# If deploying to the staging environment was successful, an approval step will wait for approval to
# deploy to the production environment.
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