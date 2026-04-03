# security.tf
# Cloud Native Security Controls

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------
# CLOUDTRAIL — Control plane audit logging (required)
# Logs every AWS API call so you can see who did what and when
# ---------------------------------------------------------

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "wiz-exercise-cloudtrail-864899846082"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "wiz-exercise-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = {
    Environment = "wiz-exercise"
  }
}

# ---------------------------------------------------------
# GUARDDUTY — Detective control (required)
# Would fire if an attacker stole EC2 IAM credentials and
# used them from a different IP address
# Imported from existing account detector
# ---------------------------------------------------------

resource "aws_guardduty_detector" "main" {
  enable = true

  tags = {
    Environment = "wiz-exercise"
  }
}

# ---------------------------------------------------------
# AWS CONFIG — Preventative control (required)
# Continuously evaluates resources against security policies.
# Rules below flag the intentional misconfigurations:
#   - open SSH port on MongoDB VM
#   - publicly readable backup bucket
# Imported from existing account recorder/channel
# ---------------------------------------------------------

resource "aws_config_configuration_recorder" "main" {
  # "default" is the existing recorder name in this account
  name     = "default"
  role_arn = "arn:aws:iam::864899846082:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  recording_group {
    all_supported                 = false
    include_global_resource_types = false
    exclusion_by_resource_types {
      resource_types = [
        "AWS::IAM::Policy",
        "AWS::IAM::User",
        "AWS::IAM::Role",
        "AWS::IAM::Group"
      ]
    }
    recording_strategy {
      use_only = "EXCLUSION_BY_RESOURCE_TYPES"
    }
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config.id
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_s3_bucket" "config" {
  bucket        = "wiz-exercise-config-864899846082"
  force_destroy = true
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# Flags security groups with SSH open to 0.0.0.0/0 (our MongoDB VM)
resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]
}

# Flags S3 buckets with public read (our backup bucket)
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]
}
