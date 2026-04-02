# mongodb.tf

# 1. Create an IAM Role for the EC2 instance
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

# 2. Attach a policy that is too permissive
# We attach AdministratorAccess to simulate the "Overly permissive CSP permissions" requirement
resource "aws_iam_role_policy_attachment" "admin_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.mongodb_role.name
}

# 3. Create the Instance Profile
resource "aws_iam_instance_profile" "mongodb_profile" {
  name = "wiz-mongodb-profile"
  role = aws_iam_role.mongodb_role.name
}

# 4. Create the Security Group for MongoDB (The Weakness: Public SSH)
resource "aws_security_group" "mongodb_sg" {
  name        = "wiz-mongodb-sg"
  description = "Security group for MongoDB VM"
  vpc_id      = module.vpc.vpc_id

  # Weakness: Allow SSH from anywhere (0.0.0.0/0)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow MongoDB traffic from EKS (Private Subnets)
  ingress {
    description = "MongoDB from EKS"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wiz-mongodb-sg"
  }
}

# 5. Launch the EC2 Instance (Outdated OS - Using Dynamic Lookup)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux_2.id  # Use the dynamic ID
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.mongodb_profile.name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              # Install MongoDB 4.4 (Outdated version as required)
              cat > /etc/yum.repos.d/mongodb-org-4.4.repo << 'EOL'
              [mongodb-org-4.4]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
              EOL
              
              yum install -y mongodb-org
              systemctl start mongod
              systemctl enable mongod
              echo "MongoDB 4.4 installed and started"
              EOF

  tags = {
    Name = "wiz-mongodb-vm"
  }
}

# Output the Public IP
output "mongodb_public_ip" {
  value = aws_instance.mongodb.public_ip
}
