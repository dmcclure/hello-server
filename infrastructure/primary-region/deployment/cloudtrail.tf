# These CloudTrail trails are used to monitor S3 buckets that will trigger the
# hello-server-test-manual and hello-server-master-manual CodePipelines.
resource "aws_s3_bucket" "cloudtrail_test" {
  bucket = "hello-server-test-manual-build-cloudtrail-logs"
  acl    = "private"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::hello-server-test-manual-build-cloudtrail-logs"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::hello-server-test-manual-build-cloudtrail-logs/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudtrail" "test_manual" {
  name                          = "hello-server-test-trigger-manual-build-events"
  s3_bucket_name                = "${aws_s3_bucket.cloudtrail_test.id}"
#   s3_key_prefix                 = "cloudtrail-events"
#   include_global_service_events = true

  event_selector {
    read_write_type = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      # Make sure to append a trailing '/' to your ARN if you want
      # to monitor all objects in a bucket.
      values = ["${aws_s3_bucket.codepipeline_test_manual.arn}/imagedefinitions.zip"]
    }
  }
}
