# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------
output "s3_root_id" {
  value       = module.static_website.s3_root_id
  description = "The name of the root S3 bucket."
}

output "cf_distribution_id" {
  value       = module.static_website.cf_distribution_id
  description = "The identifier for the CloudFront distribution."
}
