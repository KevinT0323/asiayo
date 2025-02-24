#####################
# AWS Provider 設定
#####################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-east-1"
}

##############################
# EKS Cluster 與 IAM Role 資源
##############################
resource "aws_eks_cluster" "production" {
  name = "production"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.31"

  vpc_config {
    # 使用 data source 取得現有子網路
    subnet_ids = [
      data.aws_subnet.az1.id,
      data.aws_subnet.az2.id,
      data.aws_subnet.az3.id,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = [ "sts:AssumeRole", "sts:TagSession" ],
        Effect    = "Allow",
        Principal = { Service = "eks.amazonaws.com" }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

data "aws_subnet" "az1" {
  id = "subnet-xxxxxxx1"  
}

data "aws_subnet" "az2" {
  id = "subnet-xxxxxxx2"
}

data "aws_subnet" "az3" {
  id = "subnet-xxxxxxx3"
}

##############################
# EKS Node IAM Role
##############################
resource "aws_iam_role" "node" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

##############################
# EKS MySQL Node
##############################
resource "aws_eks_node_group" "mysql" {
  cluster_name    = aws_eks_cluster.production.name
  node_group_name = "mysql"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = data.aws_subnet.az1.id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}

##############################
# EKS Web Node
##############################
resource "aws_eks_node_group" "web-server" {
  cluster_name    = aws_eks_cluster.production.name
  node_group_name = "web-server"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = data.aws_subnet.az2.id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}