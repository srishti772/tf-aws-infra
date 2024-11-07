
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


variable "PG_mysql_version" {
  description = "mysql parameter type version"
  type        = string
  default     = "mysql8.0"
}


variable "RDS_storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp3"
}


variable "RDS_allocated_storage" {
  description = "The amount of storage (in GB) to allocate for the DB instance."
  type        = number
  default     = 20
}

variable "RDS_engine" {
  description = "The database engine to use."
  type        = string
  default     = "mysql"
}

variable "RDS_engine_version" {
  description = "The version of the database engine to use."
  type        = string
  default     = "8.0.39"
}

variable "RDS_instance_class" {
  description = "The compute and memory capacity of the DB instance."
  type        = string
  default     = "db.t3.micro"
}

variable "RDS_db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "csye6225"
}

variable "RDS_username" {
  description = "The username for the master DB user."
  type        = string
  default     = "csye6225"
}

variable "RDS_password" {
  description = "The password for the master DB user."
  type        = string
}

variable "RDS_identifier" {
  description = "The identifier for the DB instance."
  type        = string
  default     = "csye6225"
}


variable "subdomain_name" {
  type    = string
  default = "dev.srishti-ahirwar.me"
}

# Required variables for the ASG
variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type = number

  default = 1
}

variable "asg_desired_capacity" {
  type = number

  default = 1
}

variable "cooldown" {
  type = number

  default = 60
}

variable "user_data_script" {
  type    = string
  default = "./user_data.tpl"

}

variable "scale_up_threshold" {
  type = number
  default = 5
}

variable "scale_down_threshold" {
  type = number
  default = 3
}