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

# ------------------------------ Create Iam roles  -----------------------------------
resource "aws_iam_role" "master" {
  name = "ed-eks-master"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statment": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role" "worker" {
  name = "ed-eks-worker"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statment": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "autoscaler" {
  name   = "ed-eks-autoscaler-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statment": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "x-ray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = "arn:aws:iam::aws:policy/autoscaler.arn"
  role       = aws_iam_role.worker.name
}

# resource "aws_iam_role_policy_attachment" "worker" {
#   depends_on = [aws_iam_role.worker]
#   role       = aws_iam_role.worker.name
# }

# =====================================================================================

# Create EKS
resource "aws_eks_cluster" "eks" {
  name     = "ed-eks-01"
  role_arn = aws_iam_role.master.arn

  vpc_config {
    subnet_ids = [
      module.nat-gateway.private_subnet_az_1_id,
      module.nat-gateway.private_subnet_az_2_id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

resource "aws_eks_node_group" "backend" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "dev"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids = [
    module.nat-gateway.private_subnet_az_1_id,
    module.nat-gateway.private_subnet_az_2_id
  ]
  capacity_type  = "ON_DEMAND"
  disk_size      = "20"
  instance_types = [var.instance_type]
  remote_access {
    ec2_ssh_key               = ""
    source_security_group_ids = [module.security-groups.worker_group_mgmt_one_id]
  }

  labels = tomap({ enc = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}