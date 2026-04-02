# alb.tf

# 1. Security Group for ALB (Public Access)
resource "aws_security_group" "alb_sg" {
  name        = "wiz-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wiz-alb-sg"
  }
}

# 2. Create the Load Balancer
resource "aws_lb" "main" {
  name               = "wiz-exercise-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false # Allow terraform to destroy it

  tags = {
    Name = "wiz-exercise-alb"
  }
}

# 3. Create a Target Group (Placeholder for K8s)
resource "aws_lb_target_group" "app" {
  name     = "wiz-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 4. Create a Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Output the ALB DNS
output "alb_dns" {
  value = aws_lb.main.dns_name
}
