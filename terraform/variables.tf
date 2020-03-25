variable "cluster-name" {
  default = "terraform-eks-teraki"
  type    = string
}

variable "cluster-workers" {
  type = object({
    desired_size = number
    max_size     = number
    min_size     = number
  })
  default = {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
}
