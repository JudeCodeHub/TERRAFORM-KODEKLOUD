
output "kke_firehose_stream_name" {
  description = "Name of the Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.firehose_stream.name
}

output "kke_s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.firehose_bucket.bucket
}

output "kke_firehose_role_arn" {
  description = "ARN of the Firehose IAM role"
  value       = aws_iam_role.firehose_role.arn
}
