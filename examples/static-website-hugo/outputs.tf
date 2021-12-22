# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------
output "s3_root_id" {
  value       = module.static_website_hugo.s3_root_id
  description = "The name of the root S3 bucket."
}

output "cf_distribution_id" {
  value       = module.static_website_hugo.cf_distribution_id
  description = "The identifier for the CloudFront distribution."
}
