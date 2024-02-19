variable "vpc1_id" {
  description = "The ID of the vpc"
  type        = string
}

variable "subnet1_ids" {
  description = "The ID of the subnet"
  type        = list(string)
}
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.2"
    }
  }
}

resource "aws_iam_role" "eks_nodes_ssm" {
  name = "eks-nodes-ssm-role1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })

  tags = {
    "kubernetes.io/cluster/cluster1" = "owned",
    "Environment" = "Test"
  }
}

resource "aws_iam_policy" "eks_nodes_ssm_access" {
  name        = "eks-nodes-ssm-access-policy1"
  description = "Policy granting EKS nodes in cluster1 access to AWS Systems Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:*",
          "ssmmessages:*",
          "ec2messages:*",
        ],
        Resource = "*"
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes_ssm_policy_attachment" {
  role       = aws_iam_role.eks_nodes_ssm.name
  policy_arn = aws_iam_policy.eks_nodes_ssm_access.arn
}

module "cluster1" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.00"

  cluster_name    = "cluster1"
  cluster_version = "1.29"
  vpc_id          = var.vpc1_id
  subnet_ids      = var.subnet1_ids

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.medium"
    }
  }

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  tags = {
    "Name" = "cluster1"
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = "cluster1" 
}

provider "kubernetes" {
  host                   = module.cluster1.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster1.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
