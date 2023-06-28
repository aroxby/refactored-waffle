variable "name" {
  type        = string
  description = "Name of service account, role, and role binding"
}

variable "rules" {
  description = "Kubernetes rules for the role"
  type = list(object({
    api_groups = list(string)
    resources  = list(string)
    verbs      = list(string)
  }))
}
