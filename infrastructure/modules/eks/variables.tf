variable "eks_admins" {
  type = list(object({
    arn      = string
    username = string
  }))
  default = [
    {
      arn      = "arn:aws:iam::523318969438:user/SandboxUser"
      username = "SandboxUser"
    }
  ]
}

variable "node_groups" {
  # For the record, I hate this rigid structure, I want to accept arbitrary objects here
  # I could say "type = list" but then if the objects have differing keys Terraform panics
  type = list(object({
    name = string
    labels = optional(map(string), {})
  }))
}
