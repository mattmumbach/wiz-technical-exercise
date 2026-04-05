# mongodb.tf

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

resource "aws_security_group" "mongodb_sg" {
  name        = "wiz-mongodb-sg"
  description = "Security group for MongoDB VM"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB from EKS"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
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

# 1. Launch the EC2 Instance (Outdated OS)
# Note: The IAM Role and Instance Profile are defined in iam.tf
resource "aws_instance" "mongodb" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.mongodb_profile.name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.mongodb_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install MongoDB 4.4 (intentionally outdated)
              cat > /etc/yum.repos.d/mongodb-org-4.4.repo << 'REPOEOF'
              [mongodb-org-4.4]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
              REPOEOF

              yum install -y mongodb-org

              # Start without auth first so we can create the admin user
              systemctl start mongod
              systemctl enable mongod
              sleep 15

              # Create admin user
              mongo admin --eval 'db.createUser({user:"wizadmin",pwd:"${var.mongo_password}",roles:[{role:"root",db:"admin"}]})'

              # Rewrite mongod.conf with auth enabled
              cat > /etc/mongod.conf << 'CONFEOF'
              storage:
                dbPath: /var/lib/mongo
              systemLog:
                destination: file
                path: /var/log/mongodb/mongod.log
                logAppend: true
              net:
                port: 27017
                bindIp: 0.0.0.0
              security:
                authorization: enabled
              CONFEOF

              systemctl restart mongod
              sleep 5

              # Create daily backup script
              cat > /usr/local/bin/mongodb-backup.sh << 'BACKUPEOF'
              #!/bin/bash
              DATE=$(date +%Y-%m-%d-%H%M)
              BACKUP_DIR=/tmp/mongodb-backup-$DATE
              BUCKET=wiz-exercise-backup-864899846082
              mongodump --uri="mongodb://wizadmin:${var.mongo_password}@localhost:27017/wiz-exercise-db?authSource=admin" --out=$BACKUP_DIR
              tar -czf /tmp/mongodb-backup-$DATE.tar.gz -C /tmp mongodb-backup-$DATE
              aws s3 cp /tmp/mongodb-backup-$DATE.tar.gz s3://$BUCKET/backups/mongodb-backup-$DATE.tar.gz
              rm -rf $BACKUP_DIR /tmp/mongodb-backup-$DATE.tar.gz
              BACKUPEOF

              chmod +x /usr/local/bin/mongodb-backup.sh
              echo "0 2 * * * root /usr/local/bin/mongodb-backup.sh >> /var/log/mongodb-backup.log 2>&1" >> /etc/crontab
              EOF

  tags = {
    Name = "wiz-mongodb-vm"
  }
}

