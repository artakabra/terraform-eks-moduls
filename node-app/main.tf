provider "aws" {
  region = var.aws_region
}

# Create VPC and public subnets
module "vpc" {
  source                  = "../modules/vpc"
  region                  = var.aws_region
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_az_1_cidr = var.public_subnet_az_1_cidr
  public_subnet_az_2_cidr = var.public_subnet_az_2_cidr
  availability_zones      = var.availability_zones
  cidr_block_any          = var.cidr_block_any
}

# Create Nat Gateways, EIPs and private subnets
module "nat-gateway" {
  source                   = "../modules/nat-gateway"
  public_subnet_az_1_id    = module.vpc.public_subnet_az_1_id
  internet_gateway         = module.vpc.internet_gateway
  public_subnet_az_2_id    = module.vpc.public_subnet_az_2_id
  vpc_id                   = module.vpc.vpc_id
  private_subnet_az_1_cidr = var.private_subnet_az_1_cidr
  private_subnet_az_2_cidr = var.private_subnet_az_2_cidr
  availability_zones       = var.availability_zones
  cidr_block_any           = var.cidr_block_any
}

# Create Security Groups
module "security-groups" {
  source       = "../modules/security-groups"
  vpc_id       = module.vpc.vpc_id
  my_public_ip = var.my_public_ip
}



# module "eks_cluster" {
#   source          = "terraform-aws-modules/eks/aws"
#   cluster_name    = "my-eks-cluster"
#   cluster_version = "1.21"

#   subnets = [
#     module.vpc.public_subnet_az1,
#     module.vpc.public_subnet_az2,
#   ]

#   worker_groups = {
#     eks_nodes = {
#       desired_capacity = 1
#       max_capacity     = 2
#       min_capacity     = 1

#       instance_type = "t3.small"
#     }
#   }
# }
