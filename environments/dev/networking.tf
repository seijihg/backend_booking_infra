# Networking configuration for Development Environment
# Creates VPC with one public and one private subnet

module "networking" {
  source = "../../modules/networking"

  project_name = var.app_name
  environment  = var.environment
  aws_region   = var.aws_region

  # VPC Configuration
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"   # 256 IPs for public resources
  private_subnet_cidr = "10.0.10.0/24"  # 256 IPs for private resources

  # Cost optimization for dev environment
  enable_nat_gateway   = false  # Saves ~$45/month - private subnet won't have internet access
  enable_flow_logs     = false  # Optional - enable for debugging
  enable_vpc_endpoints = false  # Optional - saves money in dev

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Purpose     = "Development"
    CostCenter  = "Development"
  }
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.networking.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8000  # Django default port
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-tasks-sg"
    Environment = var.environment
  }
}

# Security Group for RDS Database
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.networking.vpc_id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Optional: Add your IP for direct database access during development
  # ingress {
  #   description = "PostgreSQL from developer machine"
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   cidr_blocks = ["YOUR_IP_HERE/32"]
  # }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-rds-sg"
    Environment = var.environment
  }
}

# Security Group for ElastiCache Redis
resource "aws_security_group" "redis" {
  name        = "${var.app_name}-${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = module.networking.vpc_id

  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-redis-sg"
    Environment = var.environment
  }
}