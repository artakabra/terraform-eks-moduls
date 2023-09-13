provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
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



module "eks_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "12.2.0"
  subnets = [
    module.vpc.private_subnet_az_1,
    module.vpc.private_subnet_az_2,
  ]
  cluster_create_timeout = "1h"
  cluster_endpoint_private_access = true
  vpc_id = module.vpc.vpc_id
  worker_groups = [{
    name                 = "worker-group-1"
    instance_type        = "t2.small"
    asg_desired_capacity = 1
    additional_security_group_ids = [module.s]
  },
  ]
}
