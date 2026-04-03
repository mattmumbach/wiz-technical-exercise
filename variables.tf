variable "cluster_name" {
  default = "wiz-exercise-cluster"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "github_repo" {
  description = "mattmumbach/wiz-technical-exercise"
  type        = string
  default     = "mattmumbach/wiz-technical-exercise"
}

variable "mongo_password" {
  description = "MongoDB admin password"
  type        = string
  sensitive   = true
}

