output "vpc" {
  description = "EKS VPC Attributes"
  value = {
    vpc_id                 = module.vpc.vpc_id
    public_subnet_ids      = module.vpc.public_subnets
    private_subnet_ids     = module.vpc.private_subnets
    elasticache_subnet_ids = module.vpc.elasticache_subnets
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "elasticache_subnet_ids" {
  value = module.vpc.elasticache_subnets
}
