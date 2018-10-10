# Create an IAM role that will allow CloudWatch Events to start a CodePipeline
resource "aws_iam_role" "cloudwatch-events-test-pipeline" {
  name = "hello-server-cloudwatch-events-test-pipeline-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch-events-test-pipeline" {
  name = "hello-server-cloudwatch-events-test-pipeline-role-policy"
  role = "${aws_iam_role.cloudwatch-events-test-pipeline.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "${aws_codepipeline.test_manual.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_cloudwatch_event_rule" "manual-test-deploy" {
  name        = "hello-server-test-manual-build"
  description = "Capture the hello-server-codepipeline-test-manual-build S3 bucket being updated with a new image definition to deploy to the test environment"

  event_pattern = <<PATTERN
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["PutObject", "CompleteMultiPartUpload"],
    "resources": {
      "ARN": ["${aws_s3_bucket.codepipeline_test_manual.arn}/imagedefinitions.zip"]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "manual-test-deploy" {
  rule      = "${aws_cloudwatch_event_rule.manual-test-deploy.name}"
  target_id = "StartTestCodePipeline"
  arn       = "${aws_codepipeline.test_manual.arn}"
  role_arn  = "${aws_iam_role.cloudwatch-events-test-pipeline.arn}"
}