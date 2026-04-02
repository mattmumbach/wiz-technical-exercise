# outputs.tf

# --- Infrastructure Outputs ---
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint for the EKS cluster"
}

output "cluster_name" {
  value       = module.eks.cluster_id
  description = "The name of the EKS cluster"
}

output "github_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "The ARN of the IAM role for GitHub Actions (Add this to GitHub Secrets)"
}

output "alb_dns" {
  value = aws_lb.main.dns_name
}

# --- MongoDB Outputs ---
output "mongodb_public_ip" {
  value       = aws_instance.mongodb.public_ip
  description = "Public IP of the MongoDB VM (For reference only)"
}

output "mongodb_private_ip" {
  value       = aws_instance.mongodb.private_ip
  description = "Private IP of the MongoDB VM (Used in K8s deployment)"
}

# --- App Outputs ---
output "app_status" {
  value       = "Check GitHub Actions for deployment status"
  description = "The app is deployed via GitHub Actions. Check the Actions tab."
}

