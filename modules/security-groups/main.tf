
# Creata Securety Group for the all worker mgmt
resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_mgmt"
  description = "enable http access on port 80"
  vpc_id = var.vpc_id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${terraform.workspace}-lb_security_group"
  }
}

# Create security group for the container
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  description = "enable ssh and node-app access on port 22/3000"
  vpc_id = var.vpc_id

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_public_ip]
  }

  ingress {
    description = "node-app access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${terraform.workspace}-inctance_security_group"
  }
}


# 10.0.0.0/8
# 172.16.0.0./12
# 192.168.0.0/16