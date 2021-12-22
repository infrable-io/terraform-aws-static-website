# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------
variable "domain_name" {
  type        = string
  description = <<-EOF
  The domain name of the website. This domain name must be purchased through
  Amazon Route 53. The domain name should be of the form: <domain>.<tld>.
  EOF
}
