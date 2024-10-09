resource "aws_vpc" "a03_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "a03-vpc"
  }
}

resource "aws_internet_gateway" "a03_gateway" {
  vpc_id = aws_vpc.a03_vpc.id

  tags = {
    Name = "a03-gateway"
  }
}


resource "aws_subnet" "a03_public_subnet" {
  count                   = length(var.public_subnets_cidr_block)
  vpc_id                  = aws_vpc.a03_vpc.id
  cidr_block              = var.public_subnets_cidr_block[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]
  tags = {
    Name = "a03-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "a03_private_subnet" {
  count                   = length(var.private_subnets_cidr_block)
  vpc_id                  = aws_vpc.a03_vpc.id
  cidr_block              = var.private_subnets_cidr_block[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]
  tags = {
    Name = "a03-private-subnet-${count.index}"
  }
}

resource "aws_route_table" "a03_public_route_table" {
  vpc_id = aws_vpc.a03_vpc.id
  tags = {
    Name = "a03-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.private_subnets_cidr_block)
  subnet_id      = aws_subnet.a03_public_subnet[count.index].id
  route_table_id = aws_route_table.a03_public_route_table.id
}