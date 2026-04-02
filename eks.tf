# eks.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  cluster_name    = "wiz-exercise-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # CRITICAL FIX: Enable public API access so my laptop can reach it
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true 

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      tags = { Environment = "wiz-exercise" }
    }
  }

  enable_irsa = true

  tags = {
    Environment = "wiz-exercise"
    Project     = "TAM-Interview"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

module "eks" {
  # ... existing config ...

  access_entries = {
    "github-actions-admin" = {
      principal_arn = aws_iam_role.github_actions_role.arn
      
      policy_associations = {
        "admin" = {
          policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

output "cluster_id" {
  value = module.eks.cluster_id
}
