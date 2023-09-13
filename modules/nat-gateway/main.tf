# Allocate elastic ip in AZ1
resource "aws_eip" "eip_for_nat_gateway_az1" {
  domain = "vpc"

  tags = {
    Name = "${terraform.workspace}-nat_gateway_az1_ip"
  }
}

# Allocate elastic ip in AZ2
resource "aws_eip" "eip_for_nat_gateway_az2" {
  domain = "vpc"

  tags = {
    Name = "${terraform.workspace}-nat_gateway_az2_ip"
  }
}

# Create nat gateway in public subnet az1
resource "aws_nat_gateway" "nat_gateway_az1" {
  allocation_id = aws_eip.eip_for_nat_gateway_az1.id
  subnet_id = var.public_subnet_az_1_id

  tags = {
    Name = "${terraform.workspace}-nat_gateway_az1"
  }

  depends_on = [ var.internet_gateway ]
}

# Create nat gateway in public subnet az2
resource "aws_nat_gateway" "nat_gateway_az2" {
  allocation_id = aws_eip.eip_for_nat_gateway_az2.id
  subnet_id = var.public_subnet_az_2_id

  tags = {
    Name = "${terraform.workspace}-nat_gateway_az2"
  }

  depends_on = [ var.internet_gateway ]
}

#--------------------------Private Subnets and Routing---------------------------

resource "aws_subnet" "private_subnet_az_1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_az_1_cidr["${terraform.workspace}"]
  availability_zone = var.availability_zones[0]
  
  tags = {
    Name = "${terraform.workspace}-private_subnet_az_1"
  }
}

resource "aws_subnet" "private_subnet_az_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_az_2_cidr["${terraform.workspace}"]
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "${terraform.workspace}-private_subnet_az_2"
  }
}

resource "aws_route_table" "private_rt_az_1" {
  vpc_id = var.vpc_id
  route {
    cidr_block = var.cidr_block_any
    gateway_id = aws_nat_gateway.nat_gateway_az1.id
  }

  tags = {
    Name = "${terraform.workspace}-private_rt_az_1"
  }
}

resource "aws_route_table" "private_rt_az_2" {
  vpc_id = var.vpc_id
  route {
    cidr_block = var.cidr_block_any
    gateway_id = aws_nat_gateway.nat_gateway_az2.id
  }

  tags = {
    Name = "${terraform.workspace}-private_rt_az_2"
  }
}

resource "aws_route_table_association" "private_routes_az1" {
  route_table_id = aws_subnet.private_subnet_az_1.id
  subnet_id      = aws_subnet.private_subnet_az_1.id
}

resource "aws_route_table_association" "private_routes_az2" {
  route_table_id = aws_subnet.private_subnet_az_2.id
  subnet_id      = aws_subnet.private_subnet_az_2.id
}

#================================================================================