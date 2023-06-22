module "eks" {
  source  = "./modules/eks"
}

module "service" {
  source  = "./modules/service"
  deployment_name = "api-server"
  replicas = 2
  image = "aroxby/refactored-waffle-api-server"
  container_port = 80
  service_name = "api-server"
  load_balancer_port = 80
}