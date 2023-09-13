output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_az_1_id" {
  value = aws_subnet.public_subnet_az1.id
}

output "public_subnet_az_2_id" {
  value = aws_subnet.public_subnet_az2.id
}

output "internet_gateway" {
  value = aws_internet_gateway.internet_gateway
}
