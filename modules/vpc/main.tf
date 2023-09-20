# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr["${terraform.workspace}"]
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-vpc"
  }
}

# Create internet gatway and attach it to vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-igw"
  }
}

# Create public subnet availability zone 1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_az_1_cidr["${terraform.workspace}"]
  availability_zone = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${terraform.workspace}-public_subnet_az_1"
  }
}

# Create public subnet availability zone 2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_az_2_cidr["${terraform.workspace}"]
  availability_zone = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${terraform.workspace}-public_subnet_az_2"
  }
}

# Create route table and add public route
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.cidr_block_any
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public route table"
  }
}

# Associate public subnet az1 to "public route table"
resource "aws_route_table_association" "public_subnet_az1_route_table_associate" {
  subnet_id = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate public subnet az2 to "public route table"
resource "aws_route_table_association" "public_subnet_az2_route_table_associate" {
  subnet_id = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_route_table.id
}