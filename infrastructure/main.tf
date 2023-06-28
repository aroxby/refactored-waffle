locals {
  service_account_name = "batch-jobs"
}

module "eks" {
  source = "./modules/eks"
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
    }
  ]
  service_account_name = local.service_account_name
}
