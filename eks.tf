# eks.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  cluster_name    = "wiz-exercise-cluster"
  cluster_version = "1.32"

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

  # Grant the IAM entity that runs terraform full kubectl access
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "wiz-exercise"
    Project     = "TAM-Interview"
  }
}

