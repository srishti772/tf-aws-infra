
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "# of Public subnet"
  type        = number
  default     = 1
}


variable "private_subnets" {
  description = "# of Private subnet"
  type        = number
  default     = 1
}



variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_name" {
  description = "Prefix to identify each VPC and its resources"
  type        = string
  default     = "a03"
}
