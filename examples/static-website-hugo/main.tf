# -----------------------------------------------------------------------------
# DEPLOY AN EXAMPLE STATIC WEBSITE ON AWS.
# -----------------------------------------------------------------------------
provider "aws" {
  region  = "us-east-1"
  version = "~> 2.43"
}

module "static_website_hugo" {
  source      = "../../../terraform-aws-static-website"
  domain_name = "static-website.com"
}
