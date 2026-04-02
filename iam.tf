# iam.tf

# ---------------------------------------------------------
# PART 1: GitHub Actions OIDC Role (For the CI/CD Pipeline)
# ---------------------------------------------------------

# 1. Trust the GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 2. Create the Role
resource "aws_iam_role" "github_actions_role" {
  name = "wiz-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # REPLACE 'matthewmumbach/wiz-exercise' with your actual GitHub repo name
            "token.actions.githubusercontent.com:sub" = "repo:matthewmumbach/wiz-exercise:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# 3. Attach AdministratorAccess (Allows the pipeline to do anything)
resource "aws_iam_role_policy_attachment" "github_admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.github_actions_role.name
}

# Output the ARN so we can add it as a GitHub Secret
output "github_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}

# ---------------------------------------------------------
# PART 2: MongoDB/Bastion Instance Roles (For EC2)
# ---------------------------------------------------------

# 1. Role for MongoDB VM
resource "aws_iam_role" "mongodb_role" {
  name = "wiz-mongodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Attach Admin Access (The intentional weakness)
resource "aws_iam_role_policy_attachment" "mongodb_admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.mongodb_role.name
}

# 3. Instance Profile
resource "aws_iam_instance_profile" "mongodb_profile" {
  name = "wiz-mongodb-profile"
  role = aws_iam_role.mongodb_role.name
}
