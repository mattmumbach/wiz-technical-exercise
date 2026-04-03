# outputs.tf

# --- EKS Outputs ---
output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint for the EKS cluster"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS cluster"
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

# --- App Status ---
output "app_status" {
  value       = "Check GitHub Actions for deployment status"
  description = "The app is deployed via GitHub Actions. Check the Actions tab."
}
