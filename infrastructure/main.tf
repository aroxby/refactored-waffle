locals {
  eks_cluster_name = "recall-eks"
  service_account_name = "batch-jobs"
}

module "vpc" {
  source = "./modules/vpc"
  eks_cluster_name = local.eks_cluster_name
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = local.eks_cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  node_groups  = [
    {
      name = "general-purpose"
      labels = {
        "worker-type": "general-purpose"
      }
    },
    {
      name = "batch-jobs"
      labels = {
        "worker-type": "batch-jobs"
      }
    }
  ]
}

module "service_account" {
  source = "./modules/service-account"
  name   = local.service_account_name
  rules = [{
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["create"]
  }]

  depends_on = [module.eks]
}

module "redis" {
  source                        = "./modules/redis"
  name                          = "api-server-redis"
  ingress_security_groups       = [module.eks.node_groups.node_security_group_id]
  vpc_id                        = module.vpc.vpc_id
  elasticache_subnet_group_name = module.vpc.elasticache_subnet_group_name
}

module "service" {
  source             = "./modules/service"
  deployment_name    = "api-server"
  replicas           = 2
  image              = "aroxby/refactored-waffle-api-server:main"
  container_port     = 8888
  service_name       = "api-server"
  load_balancer_port = 80
  env = [
    {
      name  = "JOB_IMAGE_URI"
      value = "aroxby/refactored-waffle-background-job:main"
    },
    {
      name  = "REDIS_HOST"
      value = module.redis.primary_endpoint_address
    }
  ]
  service_account_name = local.service_account_name

  depends_on = [module.eks]
}
