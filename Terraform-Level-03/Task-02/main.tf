# --------------------------------
# S3 Bucket
# --------------------------------
resource "aws_s3_bucket" "firehose_bucket" {
  bucket = var.KKE_S3_BUCKET_NAME
}

# --------------------------------
# IAM Role for Firehose
# --------------------------------
resource "aws_iam_role" "firehose_role" {
  name = var.KKE_FIREHOSE_ROLE_NAME

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --------------------------------
# IAM Policy for S3 Access
# --------------------------------
resource "aws_iam_policy" "firehose_s3_policy" {
  name = "firehose-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.firehose_bucket.arn,
          "${aws_s3_bucket.firehose_bucket.arn}/*"
        ]
      }
    ]
  })
}

# --------------------------------
# Attach IAM Policy to IAM Role
# --------------------------------
resource "aws_iam_role_policy_attachment" "firehose_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_s3_policy.arn
}

# --------------------------------
# Kinesis Firehose Delivery Stream
# --------------------------------
resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = var.KKE_FIREHOSE_STREAM_NAME
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn

    # Buffering configuration
    buffering_size     = 5
    buffering_interval = 300

    # Append newline after every record
    processing_configuration {
      enabled = true

      processors {
        type = "AppendDelimiterToRecord"

        parameters {
          parameter_name  = "Delimiter"
          parameter_value = "\n"
        }
      }
    }
  }

  # Ensure IAM policy is attached before creating Firehose
  depends_on = [
    aws_iam_role_policy_attachment.firehose_policy_attachment
  ]
}
