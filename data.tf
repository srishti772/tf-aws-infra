data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "main" {
  name         = var.subdomain_name
  private_zone = false
}

data "aws_caller_identity" "current" {}

