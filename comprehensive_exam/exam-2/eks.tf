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
resource "aws_eks_cluster" "example" {
  name = "example"

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
  name = "eks-cluster-example"
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

##############################
# Data Sources - 現有子網路取得
##############################
data "aws_subnet" "az1" {
  id = "subnet-xxxxxxx1"  
}

data "aws_subnet" "az2" {
  id = "subnet-xxxxxxx2"
}

data "aws_subnet" "az3" {
  id = "subnet-xxxxxxx3"
}
