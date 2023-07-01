data "aws_region" "current" {}

data "aws_iam_policy" "cloudwatch_logs" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnet_ids
  cluster_endpoint_public_access = true

  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2551#issuecomment-1529490451
  cluster_addons = {
    vpc-cni = {
      most_recent          = true
      before_compute       = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    iam_role_additional_policies = {
      cloudwatch_logs = data.aws_iam_policy.cloudwatch_logs.arn
    }
  }

  eks_managed_node_groups = {
    for node_group in var.node_groups : node_group.name => merge(
      {
        instance_types = ["t3.micro"]

        min_size     = 1
        max_size     = 2
        desired_size = 1
      },
      node_group,
    )
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

module "cluster_autoscaler" {
  source = "git::https://github.com/akshaykrjain/terraform-aws-eks-cluster-autoscaler.git?ref=6144e7bc7d88d87eac98709abd6fd8887ca47eeb"

  enabled = true

  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  aws_region                       = data.aws_region.current.name

  helm_chart_version = "9.29.1"
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
