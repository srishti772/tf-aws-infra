
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


variable "vpc_name" {
  description = "Prefix to identify each VPC and its resources"
  type        = string
  default     = "a04"
}


variable "ec2_name" {
  description = "Prefix to identify each EC2 instance"
  type        = string
  default     = "a04"
}

variable "golden_ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-0b844a6a7aa2a3aff"
}

variable "application_port" {
  description = "Port on which the Node js application runs"
  type        = number
}

variable "incoming_traffic" {
  description = "CIDR for Incoming traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "CIDR for Incoming traffic"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/my_key.pem.pub"
}

variable "root_volume_size" {
  description = "Size of the root block device in GB"
  type        = number
  default     = 25 # GB
}

variable "root_volume_type" {
  description = "Type of the root block device"
  type        = string
  default     = "gp2"
}

variable "root_volume_delete_on_termination" {
  description = "Whether to delete the root block device on termination"
  type        = bool
  default     = true
}
