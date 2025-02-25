#####################
# AWS Provider 設定
#####################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }
  }
}

provider "aws" {
  region = "ap-east-1"
}

#####################
# opt-in-status 過濾條件為 opt-in-not-required，表示只選擇不需要手動啟用的可用區，
# 這樣可以排除 AWS Local Zones（因為它們通常需要手動啟用）。
#####################
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws" # 使用 terraform-aws-modules/vpc/aws 模組來建立一個 VPC
  version = "5.8.1"

  name = "education-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3) # 從 AWS 可用區（data.aws_availability_zones.available.names）中選取前三個可用區，確保高可用性。

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] # 用來部署內部資源，如 EC2 或 EKS Worker Nodes。
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] # 通常用來部署有公網訪問需求的資源，如 ALB（應用程式負載均衡器）。

  enable_nat_gateway   = true # 啟用 NAT Gateway，使私有子網內的資源可以訪問外部網際網路（如下載軟體包），但不允許外部流量直接訪問私有子網內的資源。
  single_nat_gateway   = true # 使用單一 NAT Gateway，而不是為每個可用區建立一個 NAT Gateway，以降低成本。
  enable_dns_hostnames = true # 啟用 DNS 主機名稱解析，使 VPC 內的 EC2 可以透過 DNS 解析內部 IP。

  public_subnet_tags = { # 為公共子網（Public Subnets）新增標籤，標明 Kubernetes LoadBalancer（ELB）可以使用這些子網來提供對外服務。
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = { # 為私有子網（Private Subnets）新增標籤，標明 Kubernetes 的內部 ELB（如內部服務的 LoadBalancer）應該使用這些子網。
    "kubernetes.io/role/internal-elb" = 1
  }
}

#####################
# EKS 相關設定
#####################
module "eks" {
  source  = "terraform-aws-modules/eks/aws" # 使用 terraform-aws-modules/eks/aws 模組來建立 EKS 叢集。
  version = "20.8.5"

  cluster_name    = "production"
  cluster_version = "1.32"

  cluster_endpoint_public_access           = true # 開啟 EKS API Server 的公開存取，允許從外部直接存取 Kubernetes API。
  enable_cluster_creator_admin_permissions = true # 允許 Terraform 建立的使用者擁有 EKS 管理權限。

  cluster_addons = {
    # 開啟 AWS EBS CSI 驅動程式（允許 Kubernetes 使用 EBS 卷（Elastic Block Store） 作為持久儲存）。
    aws-ebs-csi-driver = { 
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn # 指定 EBS CSI 需要的 IAM 角色，這個角色來自 module.irsa-ebs-csi
    }
  }

  vpc_id     = module.vpc.vpc_id # EKS 叢集將部署在 module.vpc 所管理的 VPC 內
  subnet_ids = module.vpc.private_subnets # 指定 私有子網（private subnets） 給 EKS 節點

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64" # 使用 Amazon Linux 2（AL2） 作為 EKS 節點的 OS。

  }

  eks_managed_node_groups = {
    mysql = {
      name = "mysql-node-group"

      instance_types = ["t3.large"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    web = {
      name = "web-node-group"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

# 讀取 AWS 內建的 AmazonEBSCSIDriverPolicy（EBS CSI Driver 需要這個 IAM 權限來管理 EBS 磁碟）。
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# 設定 IRSA（IAM Roles for Service Accounts），讓 Kubernetes 的 EBS CSI 驅動程式使用 IAM 權限。
module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"] # 限定 Kubernetes ServiceAccount ebs-csi-controller-sa 才能使用這個 IAM 角色。
}