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
