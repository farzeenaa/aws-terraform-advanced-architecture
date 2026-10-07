terraform {
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

# 1. Advanced Virtual Private Cloud (VPC)
resource "aws_vpc" "advanced_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "enterprise-vpc"
  }
}

# 2. Public Subnets (For Load Balancer) spanning 2 Availability Zones
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.advanced_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "enterprise-public-1a" }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.advanced_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "enterprise-public-1b" }
}

# 3. Private Subnets (Isolated Zone for Web Servers)
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.advanced_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "enterprise-private-1a" }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.advanced_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "enterprise-private-1b" }
}

# 4. Internet Gateway (Front Door)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.advanced_vpc.id
  tags   = { Name = "enterprise-igw" }
}

# 5. Public Route Table & Association
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.advanced_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "enterprise-public-rt" }
}

resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Security Group for the Public Application Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "enterprise-alb-sg"
  description = "Allow inbound HTTP public web traffic to ALB"
  vpc_id      = aws_vpc.advanced_vpc.id

  ingress {
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

  tags = { Name = "enterprise-alb-sg" }
}

# 7. Security Group for Private Web Servers (Strict Layered Security)
resource "aws_security_group" "web_sg" {
  name        = "enterprise-web-sg"
  description = "Allow inbound traffic ONLY from the ALB"
  vpc_id      = aws_vpc.advanced_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "enterprise-web-sg" }
}

# 8. External Application Load Balancer
resource "aws_lb" "enterprise_alb" {
  name               = "enterprise-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]

  tags = { Name = "enterprise-alb" }
}

# 9. ALB Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "enterprise-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.advanced_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 10. ALB Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.enterprise_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 11. Private Web Server Instance 1 (Moved to Public Subnet for software downloads)
resource "aws_instance" "web_server_1" {
  ami                    = "ami-0e2c8caa4b6378d8c" 
  instance_type          = "t3.micro"             
  subnet_id              = aws_subnet.public_az1.id # ◄ CHANGE THIS LINE TO public_az1
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              echo "<h1>Enterprise App Server - Node 1A (High Availability)</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = { Name = "enterprise-web-server-1" }
}

# 12. Private Web Server Instance 2 (Moved to Public Subnet for software downloads)
resource "aws_instance" "web_server_2" {
  ami                    = "ami-0e2c8caa4b6378d8c" 
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_az2.id # ◄ CHANGE THIS LINE TO public_az2
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              echo "<h1>Enterprise App Server - Node 1B (High Availability)</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = { Name = "enterprise-web-server-2" }
}


# 13. Attach Web Server 1 to Target Group
resource "aws_lb_target_group_attachment" "attach_server_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

# 14. Attach Web Server 2 to Target Group
resource "aws_lb_target_group_attachment" "attach_server_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# 15. Formatted Public Endpoint Output Variable
output "load_balancer_dns" {
  value       = aws_lb.enterprise_alb.dns_name
  description = "The public URL of your Application Load Balancer"
}
