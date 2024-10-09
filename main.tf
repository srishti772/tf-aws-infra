#Creating VPC
resource "aws_vpc" "a03_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

#Creating Internet Gateway and attaching to VPC
resource "aws_internet_gateway" "a03_gateway" {
  vpc_id = aws_vpc.a03_vpc.id

  tags = {
    Name = "${var.vpc_name}-gateway"
  }
}

#Creating public subnets
resource "aws_subnet" "a03_public_subnet" {
  count                   = var.public_subnets
  vpc_id                  = aws_vpc.a03_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]
  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index}"
  }
}
#Creating private subnets
resource "aws_subnet" "a03_private_subnet" {
  count                   = var.private_subnets
  vpc_id                  = aws_vpc.a03_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, 255 - count.index)
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones[count.index]
  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index}"
  }
}
#Creating public route table
resource "aws_route_table" "a03_public_route_table" {
  vpc_id = aws_vpc.a03_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.a03_gateway.id
  }
  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}
#Relating public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = var.public_subnets
  subnet_id      = aws_subnet.a03_public_subnet[count.index].id
  route_table_id = aws_route_table.a03_public_route_table.id
}

#Creating private route table
resource "aws_route_table" "a03_private_route_table" {
  vpc_id = aws_vpc.a03_vpc.id
  tags = {
    Name = "${var.vpc_name}-private-route-table"
  }
}
#Relating private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = var.private_subnets
  subnet_id      = aws_subnet.a03_private_subnet[count.index].id
  route_table_id = aws_route_table.a03_private_route_table.id
}

