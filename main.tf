# main.tf
terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket  = "wiz-exercise-tfstate-864899846082"
    key     = "wiz-exercise/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
