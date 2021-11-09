resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.app_name
  }
}

# Subnets(Public)
resource "aws_subnet" "publics" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  availability_zone = var.azs[count.index]
  cidr_block = var.public_subnet_cidrs[count.index]

  tags = {
    Name = "${var.app_name}-public-${count.index}"
  }
}

# Subnet(Private)
resource "aws_subnet" "privates" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name = "${var.app_name}-private-${count.index}"
  }
}

# Subnet
resource "aws_subnet" "ec2" {
  cidr_block        = "10.0.100.0/24"
  availability_zone = "ap-northeast-1a"
  vpc_id            = aws_vpc.main.id

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-ec2"
  }
}

# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.app_name
  }
}

# RouteTable
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.app_name
  }
}

# Route
resource "aws_route" "main" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.main.id
  gateway_id = aws_internet_gateway.main.id
}

# RouteTableAssociation(Public)
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id = element(aws_subnet.publics.*.id, count.index)
  route_table_id = aws_route_table.main.id
}

# RouteTableAssociation(EC2)
resource "aws_route_table_association" "ec2" {
  subnet_id = aws_subnet.ec2.id
  route_table_id = aws_route_table.main.id
}