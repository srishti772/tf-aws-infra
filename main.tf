#Creating VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.vpc_name}"
  }
}

#Creating Internet Gateway and attaching to VP
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-gateway"
  }
}

#Creating public subnets
resource "aws_subnet" "public" {
  count                   = var.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index}"
  }
}

#Creating public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}
#Relating public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = var.public_subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
#Creating private subnets
resource "aws_subnet" "private" {
  count                   = var.private_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, 255 - count.index)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index}"
  }
}
#Creating private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.vpc_name}-private-route-table"
  }
}
#Relating private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = var.private_subnets
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "app_sg" {
  vpc_id      = aws_vpc.this.id
  name        = "application security group"
  description = "Security group for web application EC2 instances"

  tags = {
    Name = "application security group"
  }

  # SSH rule for port 22
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }



  # Node js rule 
  ingress {
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_key_pair" "ec2" {
  key_name   = "${var.ec2_name}-key"
  public_key = file(var.public_key_path)
}

# Creating EC2 Instance
resource "aws_instance" "ec2" {
  ami                         = var.golden_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  key_name                    = aws_key_pair.ec2.key_name
  disable_api_termination     = false
  depends_on                  = [aws_db_instance.this]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  user_data                   = <<-EOF
#!/bin/bash
sudo -u csye6225 bash <<'EOL'
cd /opt/csye6225/webapp
touch .env
echo "PORT=${var.application_port}" >> .env
echo "MYSQL_USER=${var.RDS_username}" >> .env
echo "MYSQL_PASSWORD=${var.RDS_password}" >> .env
echo "MYSQL_HOST=${aws_db_instance.this.address}" >> .env
echo "MYSQL_PORT=${aws_db_instance.this.port}" >> .env
echo "MYSQL_DATABASE_TEST=test_db" >> .env
echo "MYSQL_DATABASE_PROD=${var.RDS_db_name}" >> .env
echo "STATSD_CLIENT=127.0.0.1" >> .env
echo "STATSD_PORT=8125" >> .env
echo "BUCKET_NAME=${aws_s3_bucket.this.bucket}" >> .env
echo "BUCKET_REGION=${var.aws_region}" >> .env
EOL
sudo systemctl daemon-reload
sudo systemctl restart webapp

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/csye6225/webapp/cloudwatch-config.json \
-s
sudo systemctl restart amazon-cloudwatch-agent


EOF


  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = var.root_volume_delete_on_termination

  }

  tags = {
    Name = "${var.ec2_name}-instance"
  }
}



resource "aws_db_parameter_group" "mysql_param_group" {
  name        = "mysql-parameter-group"
  family      = var.PG_mysql_version
  description = "MySQL parameter group"

}
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.vpc_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.vpc_name}-db-subnet-group"
  }
}


resource "aws_security_group" "db_sg" {
  vpc_id      = aws_vpc.this.id
  name        = "database security group"
  description = "Security group for RDS instances"

  tags = {
    Name = "database security group"
  }

  # SSH rule for port 3306 MYSQL
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }


}
resource "aws_db_instance" "this" {
  identifier = var.RDS_identifier

  storage_type = var.RDS_storage_type

  allocated_storage      = var.RDS_allocated_storage
  db_name                = var.RDS_db_name
  engine                 = var.RDS_engine
  engine_version         = var.RDS_engine_version
  instance_class         = var.RDS_instance_class
  username               = var.RDS_username
  password               = var.RDS_password
  parameter_group_name   = aws_db_parameter_group.mysql_param_group.name
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
}


resource "aws_iam_role" "ec2" {
  name = "ec2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_policy" "s3Bucket_policy" {
  name        = "S3BucketAccessPolicy"
  description = "Policy for read, write, and delete access to the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}


# Attach the CloudWatchAgentServerPolicy to the IAM role for EC2
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
# Attach Custom S3 policy to s3Bucket IAM role for EC2

resource "aws_iam_role_policy_attachment" "s3Bucket_policy" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3Bucket_policy.arn
}
#Instance Profile to attach to EC2
resource "aws_iam_instance_profile" "ec2" {
  name = "ec2"
  role = aws_iam_role.ec2.name
}




resource "aws_s3_bucket" "this" {
  bucket        = uuid()
  force_destroy = true

}


resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id = "TransitionToStandardIA"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    status = "Enabled"
  }
}


resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.subdomain_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.ec2.public_ip]
}




resource "aws_security_group" "lb_sg" {
  vpc_id      = aws_vpc.this.id
  name        = "load balancer security group"
  description = "Security group for load balancer"

  tags = {
    Name = "load balancer security group"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.incoming_traffic
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.incoming_traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# Creating a Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.ec2_name}-launch-template-"
  image_id      = var.golden_ami_id
  instance_type = var.instance_type

  key_name = aws_key_pair.ec2.key_name


  network_interfaces {
    associate_public_ip_address = true
  }

  # User Data
  user_data = <<-EOF
    #!/bin/bash
    sudo -u csye6225 bash <<'EOL'
    cd /opt/csye6225/webapp
    touch .env
    echo "PORT=${var.application_port}" >> .env
    echo "MYSQL_USER=${var.RDS_username}" >> .env
    echo "MYSQL_PASSWORD=${var.RDS_password}" >> .env
    echo "MYSQL_HOST=${aws_db_instance.this.address}" >> .env
    echo "MYSQL_PORT=${aws_db_instance.this.port}" >> .env
    echo "MYSQL_DATABASE_TEST=test_db" >> .env
    echo "MYSQL_DATABASE_PROD=${var.RDS_db_name}" >> .env
    echo "STATSD_CLIENT=127.0.0.1" >> .env
    echo "STATSD_PORT=8125" >> .env
    echo "BUCKET_NAME=${aws_s3_bucket.this.bucket}" >> .env
    echo "BUCKET_REGION=${var.aws_region}" >> .env
    EOL
    sudo systemctl daemon-reload
    sudo systemctl restart webapp

    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/csye6225/webapp/cloudwatch-config.json \
    -s
    sudo systemctl restart amazon-cloudwatch-agent
  EOF

  # Block device mapping
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = var.root_volume_delete_on_termination
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids  = [aws_security_group.app_sg.id]
  disable_api_termination = true


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.ec2_name}-launch-template"
    }
  }
}


#Output

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.ec2.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance and check webapp service status"
  value       = "ssh -i ${var.public_key_path} ubuntu@${aws_instance.ec2.public_ip} && sudo systemctl status webapp.service && sudo node /opt/csye6225/webapp/server.js"
}


output "db_host" {
  description = "DB host"
  value       = "${aws_db_instance.this.endpoint} "
}


