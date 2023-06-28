# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

data "aws_iam_policy" "cloudwatch_logs" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

locals {
  cluster_name = "recall-eks"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "education-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    iam_role_additional_policies = {
      cloudwatch_logs = data.aws_iam_policy.cloudwatch_logs.arn
    }
  }

  eks_managed_node_groups = {

    one = {
      name = "node-group-1"

      instance_types = ["t3.micro"]

      # This is supplied to the AWS EKS Optimized AMI
      # bootstrap script https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh
      bootstrap_extra_args = "--kubelet-extra-args '--max-pods=10'"

      # This user data will be injected prior to the user data provided by the
      # AWS EKS Managed Node Group service (contains the actually bootstrap configuration)
      # `USE_MAX_PODS` disables the EKS default of setting max pods based on EC2 instance type
      pre_bootstrap_user_data = <<-EOT
        export USE_MAX_PODS=false
      EOT

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.micro"]

      instance_types = ["t3.micro"]

      # This is supplied to the AWS EKS Optimized AMI
      # bootstrap script https://github.com/awslabs/amazon-eks-ami/blob/master/files/bootstrap.sh
      bootstrap_extra_args = "--kubelet-extra-args '--max-pods=10'"

      # This user data will be injected prior to the user data provided by the
      # AWS EKS Managed Node Group service (contains the actually bootstrap configuration)
      # `USE_MAX_PODS` disables the EKS default of setting max pods based on EC2 instance type
      pre_bootstrap_user_data = <<-EOT
        export USE_MAX_PODS=false
      EOT

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_users = [
    for eks_admin in var.eks_admins : {
      userarn  = eks_admin.arn
      username = eks_admin.username
      groups   = ["system:masters"]
    }
  ]
}

module "cloudwatch_logs" {
  source = "git::https://github.com/Mattie112/terraform-aws-eks-cloudwatch-logs.git?ref=dd02d75cfb96fb754c56ca7f02281cd8e64e1a06"

  enabled = true

  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  worker_iam_role_name             = module.eks.cluster_iam_role_name
  region                           = data.aws_region.current.name

  helm_chart_version = "0.1.27"
}
