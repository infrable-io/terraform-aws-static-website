# -----------------------------------------------------------------------------
# DEPLOY A STATIC WEBSITE ON AWS.
# This Terraform module deploys the resources necessary to host a static
# website on AWS. It includes the following:
#   * Access logging via Amazon S3
#   * TLS encryption via AWS Certificate Manager
#   * Content delivery via Amazon CloudFront
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer
# compatible with any versions below 0.12.
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

locals {
  # Example: static-website.com → static-website-com
  domain_name = lower(replace(var.domain_name, ".", "-"))
}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# S3 BUCKET (LOGGING)
# This S3 bucket will contain the access logs for the website.
# NOTE: The bucket name is generated using the `domain_name` variable.
# The bucket name must contain only lowercase letters, numbers, periods (.),
# and dashes (-) (i.e. it must be a valid DNS name).
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "s3_logs" {
  bucket = "${local.domain_name}-logs"
  acl    = "log-delivery-write"
}

# -----------------------------------------------------------------------------
# S3 BUCKET (ROOT)
# This S3 bucket will contain the static content for the website.
# NOTE: The bucket name is generated using the `domain_name` variable.
# The bucket name must contain only lowercase letters, numbers, periods (.),
# and dashes (-) (i.e. it must be a valid DNS name).
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "s3_root" {
  bucket = "${local.domain_name}-root"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  logging {
    target_bucket = aws_s3_bucket.s3_logs.id
    target_prefix = "s3/"
  }
}

# -----------------------------------------------------------------------------
# ACM CERTIFICATE
# TLS certificate provisioned by AWS Certificate Manager.
# This certificate applies to both the root domain (<domain>.<tld>) and the www
# subdomain (www.<domain>.<tld>).
# -----------------------------------------------------------------------------
resource "aws_acm_certificate" "certificate" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["www.${var.domain_name}"]
}

# -----------------------------------------------------------------------------
# RETRIEVE THE HOSTED ZONE ID FOR THE DOMAIN NAME
# -----------------------------------------------------------------------------
data "aws_route53_zone" "hosted_zone" {
  name         = var.domain_name
  private_zone = false
}

# -----------------------------------------------------------------------------
# ACM CERTIFICATE VALIDATION (ROOT)
# Validates the ACM certificate for the root domain via DNS.
# -----------------------------------------------------------------------------
resource "aws_route53_record" "certificate_validation_root" {
  name    = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.hosted_zone.id
  records = [aws_acm_certificate.certificate.domain_validation_options.0.resource_record_value]
  # TTL is required for non-alias records.
  ttl = 60
}

# -----------------------------------------------------------------------------
# ACM CERTIFICATE VALIDATION (WWW)
# Validates the ACM certificate for the www subdomain via DNS.
# -----------------------------------------------------------------------------
resource "aws_route53_record" "certificate_validation_www" {
  name    = aws_acm_certificate.certificate.domain_validation_options.1.resource_record_name
  type    = aws_acm_certificate.certificate.domain_validation_options.1.resource_record_type
  zone_id = data.aws_route53_zone.hosted_zone.id
  records = [aws_acm_certificate.certificate.domain_validation_options.1.resource_record_value]
  # TTL is required for non-alias records.
  ttl = 60
}

# -----------------------------------------------------------------------------
# CLOUDFRONT DISTRIBUTION
# Creates a distributed content delivery network using Amazon CloudFront.
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "distribution" {
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"

  custom_error_response {
    error_caching_min_ttl = 60
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = true
    }
    target_origin_id       = local.domain_name
    viewer_protocol_policy = "redirect-to-https"
  }

  logging_config {
    bucket = aws_s3_bucket.s3_logs.bucket_domain_name
    prefix = "cdn/"
  }

  origin {
    domain_name = aws_s3_bucket.s3_root.website_endpoint
    origin_id   = local.domain_name

    custom_origin_config {
      http_port  = 80
      https_port = 443
      # Note: Amazon S3 does not support HTTPS connections when configured as a
      # website endpoint. You must specify HTTP Only as the Origin Protocol
      # Policy.
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
}

# -----------------------------------------------------------------------------
# DNS RECORD (ROOT)
# Creates an A record mapping the root domain name to the Amazon CloudFront
# distribution.
# -----------------------------------------------------------------------------
resource "aws_route53_record" "dns_record_root" {
  name    = var.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.hosted_zone.id

  alias {
    name = aws_cloudfront_distribution.distribution.domain_name
    # The hosted zone ID when creating an alias record that routes traffic to a
    # CloudFront distribution will always be Z2FDTNDATAQYW2.
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

# -----------------------------------------------------------------------------
# DNS RECORD (WWW)
# Creates an A record mapping the root domain name to the Amazon CloudFront
# distribution.
# -----------------------------------------------------------------------------
resource "aws_route53_record" "dns_record_www" {
  name    = "www.${var.domain_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.hosted_zone.id

  alias {
    name = aws_cloudfront_distribution.distribution.domain_name
    # The hosted zone ID when creating an alias record that routes traffic to a
    # CloudFront distribution will always be Z2FDTNDATAQYW2.
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
