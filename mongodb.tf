# mongodb.tf

# 1. Launch the EC2 Instance (Outdated OS)
# Note: The IAM Role and Instance Profile are defined in iam.tf
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux_2.id
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

