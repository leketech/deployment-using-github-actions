# Define the IAM policy document for the EKS cluster role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create the IAM role for the EKS cluster
resource "aws_iam_role" "example" {
  name               = "eks-cluster-cloud-1"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach the AmazonEKSClusterPolicy to the EKS cluster IAM role
resource "aws_iam_role_policy_attachment" "example_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the public subnets in the default VPC and filter by supported availability zones
data "aws_subnet" "public_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
}

data "aws_subnet" "public_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1b"]
  }
}

data "aws_subnet" "public_c" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1c"]
  }
}

data "aws_subnet" "public_d" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1d"]
  }
}

data "aws_subnet" "public_f" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1f"]
  }
}

# Provision the EKS cluster
resource "aws_eks_cluster" "example" {
  name     = "EKS_CLOUD"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.public_a.id,
      data.aws_subnet.public_b.id,
      data.aws_subnet.public_c.id,
      data.aws_subnet.public_d.id,
      data.aws_subnet.public_f.id
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example_AmazonEKSClusterPolicy,
  ]
}

# Create the IAM role for the EKS node group
resource "aws_iam_role" "example1" {
  name = "eks-node-group-cloud-1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the AmazonEKSWorkerNodePolicy to the EKS node group IAM role
resource "aws_iam_role_policy_attachment" "example_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.example1.name
}

# Attach the AmazonEKS_CNI_Policy to the EKS node group IAM role
resource "aws_iam_role_policy_attachment" "example_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.example1.name
}

# Attach the AmazonEC2ContainerRegistryReadOnly policy to the EKS node group IAM role
resource "aws_iam_role_policy_attachment" "example_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.example1.name
}

# Create the EKS node group
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "Node-cloud"
  node_role_arn   = aws_iam_role.example1.arn
  subnet_ids      = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id,
    data.aws_subnet.public_c.id,
    data.aws_subnet.public_d.id,
    data.aws_subnet.public_f.id
  ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  instance_types = ["t2.medium"]

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.example_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example_AmazonEC2ContainerRegistryReadOnly,
  ]
}
