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
}

resource "aws_security_group" "allow_eks_nodes_to_default_vpc" {
  name        = "allow_eks_nodes_to_default_vpc"
  description = "Allows redis traffic from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from EKS Nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_groups.node_security_group_id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis_subnet_group"
  subnet_ids = module.vpc.elasticache_subnet_ids
}

resource "aws_elasticache_replication_group" "api_redis" {
  replication_group_id    = "api-server-redis"
  description             = "Shared cache for application"
  node_type               = "cache.t3.micro"
  num_node_groups         = 1
  replicas_per_node_group = 0
  security_group_ids      = [aws_security_group.allow_eks_nodes_to_default_vpc.id]
  subnet_group_name       = aws_elasticache_subnet_group.redis_subnet_group.name
  apply_immediately       = true
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
      value = aws_elasticache_replication_group.api_redis.primary_endpoint_address
    }
  ]
  service_account_name = local.service_account_name
}
