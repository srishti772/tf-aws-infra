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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.incoming_traffic
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
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
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
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.incoming_traffic
    ipv6_cidr_blocks = ["::/0"]
  }

  # HTTPS
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.incoming_traffic
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}




# Creating a Launch Template for Autoscaling
resource "aws_launch_template" "this" {
  name          = "csye6225-launchtemplate"
  image_id      = var.golden_ami_id
  instance_type = var.instance_type

  key_name = aws_key_pair.ec2.key_name


  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]

  }

  user_data = base64encode(templatefile("./user_data.tpl", {
    application_port = var.application_port,
    RDS_username     = var.RDS_username,
    RDS_password     = var.RDS_password,
    db_host          = aws_db_instance.this.address,
    db_port          = aws_db_instance.this.port,
    RDS_db_name      = var.RDS_db_name,
    bucket_name      = aws_s3_bucket.this.bucket,
    aws_region       = var.aws_region,
    base_url         = var.subdomain_name,
    sns_topic        = aws_sns_topic.this.arn
  }))
  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = var.root_volume_delete_on_termination
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  disable_api_termination = true


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.ec2_name}-launch-template"
    }
  }
}




# Auto Scaling Group Definition
resource "aws_autoscaling_group" "this" {
  name = "csye6225-asg"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  default_cooldown    = var.cooldown
  vpc_zone_identifier = aws_subnet.public[*].id
  force_delete        = true
  # Auto Scaling Group Tags
  tag {

    key                 = "Name"
    value               = "csye6225_asg"
    propagate_at_launch = true


  }
  target_group_arns = [aws_lb_target_group.this.arn]
  depends_on        = [aws_db_instance.this]


}


resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scaleUpPolicy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = 1
  cooldown               = var.cooldown
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
}

# CloudWatch Metric Alarm - CPU Utilization (Scale Up)
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_up_threshold

  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scaleDownPolicy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  scaling_adjustment     = -1
  cooldown               = var.cooldown
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"

}


# CloudWatch Metric Alarm - CPU Utilization (Scale Down)
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_down_threshold

  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
}

resource "aws_lb" "this" {
  name               = "csye6225-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public[*].id
  enable_http2       = true

  tags = {
    Application = "webapp"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn


  }
}

resource "aws_lb_target_group" "this" {
  name        = "app-target-group"
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}
resource "aws_sns_topic" "this" {
  name = "webapp-email-notification"
}

resource "aws_iam_policy" "sns_publish" {
  name = "lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.this.arn
      }
    ]
  })
}
#Allow EC2 to publish to SNS topic
resource "aws_iam_role_policy_attachment" "snspublish_policy" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.sns_publish.arn
}


resource "aws_lambda_function" "this" {
  filename      = var.serverless
  function_name = "serverless"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = var.runtime
  timeout       = 300

  environment {
    variables = {
      MAILGUN_API_KEY     = var.mailgun_api_key
      DOMAIN              = var.subdomain_name
      MYSQL_HOST          = aws_db_instance.this.address
      MYSQL_USER          = var.RDS_username
      MYSQL_PASSWORD      = var.RDS_password
      MYSQL_DATABASE_PROD = var.RDS_db_name
      MYSQL_PORT          = aws_db_instance.this.port

    }
  }

  depends_on = [aws_iam_role_policy_attachment.sns_logging_policy_attachment]
}


resource "aws_iam_role" "lambda" {
  name = "lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_logging_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}


resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  function_name = aws_lambda_function.this.function_name
  source_arn    = aws_sns_topic.this.arn
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this.arn


}



