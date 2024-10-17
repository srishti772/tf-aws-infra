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

resource "aws_security_group" "this" {
  vpc_id      = aws_vpc.this.id
  name        = "${var.vpc_name}-app-sg"
  description = "Security group for web application EC2 instances"

  tags = {
    Name = "${var.vpc_name}-app-sg"
  }
}

# SSH rule for port 22
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.incoming_traffic
}

# HTTP rule for port 80
resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.incoming_traffic
}

# HTTPS rule for port 443
resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.incoming_traffic
}

# Custom application rule for port 3000
resource "aws_security_group_rule" "webapp" {
  type              = "ingress"
  from_port         = var.application_port
  to_port           = var.application_port
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.incoming_traffic
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
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.ec2.key_name
  disable_api_termination     = false

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = var.root_volume_delete_on_termination

  }

  tags = {
    Name = "${var.ec2_name}-instance"
  }
}