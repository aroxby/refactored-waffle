module "eks" {
  source  = "./modules/eks"
}

module "service" {
  source  = "./modules/service"
  deployment_name = "api-server"
  replicas = 2
  image = "aroxby/refactored-waffle-api-server:main"
  container_port = 8888
  service_name = "api-server"
  load_balancer_port = 80
  env = [
    {
      name = "JOB_IMAGE_URI"
      value = "aroxby/refactored-waffle-background-job:main"
    }
  ]
}
