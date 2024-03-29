# -----------------------------------------------------------------------------
# DEPLOY AN EXAMPLE STATIC WEBSITE ON AWS.
# -----------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1"
}

module "static_website" {
  source      = "../../../terraform-aws-static-website"
  domain_name = "static-website.com"
}
