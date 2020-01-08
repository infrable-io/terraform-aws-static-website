# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------
output "s3_root_id" {
  value       = aws_s3_bucket.s3_root.id
  description = "The name of the root S3 bucket."
}

output "cf_distribution_id" {
  value       = aws_cloudfront_distribution.distribution.id
  description = "The identifier for the CloudFront distribution."
}
