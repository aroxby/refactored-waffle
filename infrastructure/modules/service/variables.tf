variable "deployment_name" {
  type        = string
  description = "Name of application deployment"
}

variable "replicas" {
  type        = number
  description = "Number of service tasks to run"
}

variable "image" {
  type        = string
  description = "Name and tag of image to run"
}

variable "container_port" {
  type        = number
  description = "Port number for the container to listen on"
}

variable "service_name" {
  type        = string
  description = "Name of service load balancer"
}

variable "load_balancer_port" {
  type        = number
  description = "Port number for the load balancer to listen on"
}

variable "env" {
  description = "Container environment variables"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "service_account_name" {
  type        = string
  description = "Name of service account for the deployment"
}
