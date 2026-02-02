  # Uncomment for remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "candle-shop/terraform.tfstate"
  #   region         = "eu-central-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }


# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  project_name       = var.project_name
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Subnets Module
module "subnets" {
  source = "./modules/subnets"

  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  availability_zones = var.availability_zones
  environment      = var.environment
  project_name     = var.project_name
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# NAT Gateway Module
module "nat" {
  source = "./modules/nat"

  public_subnet_id = module.subnets.public_subnet_ids[0]
  project_name     = var.project_name
  environment      = var.environment
}

# Route Tables Module
module "route_tables" {
  source = "./modules/route_tables"

  vpc_id               = module.vpc.vpc_id
  internet_gateway_id  = module.vpc.internet_gateway_id
  nat_gateway_id       = module.nat.nat_gateway_id
  public_subnet_ids    = module.subnets.public_subnet_ids
  private_subnet_ids   = module.subnets.private_subnet_ids
  project_name         = var.project_name
  environment          = var.environment
}

# Security Groups Module
module "security" {
  source = "./modules/security"

  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  project_name     = var.project_name
  environment      = var.environment
  allowed_ssh_cidr = var.allowed_ssh_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.subnets.public_subnet_ids
  alb_security_group_id = module.security.alb_sg_id
  project_name       = var.project_name
  environment        = var.environment
  
  # Optional: Add ACM certificate ARN for HTTPS
  # certificate_arn = var.certificate_arn
}

# EC2 Instances Module
module "ec2" {
  source = "./modules/ec2"

  vpc_id                = module.vpc.vpc_id
  public_subnet_id      = module.subnets.public_subnet_ids[0]
  private_subnet_id     = module.subnets.private_subnet_ids[0]
  frontend_sg_id        = module.security.frontend_sg_id
  backend_sg_id         = module.security.backend_sg_id
  alb_target_group_arn  = module.alb.target_group_arn
  
  project_name          = var.project_name
  environment           = var.environment
  key_name              = var.key_name
  instance_type         = var.instance_type
  
  backend_user_data     = var.backend_user_data
  frontend_user_data    = var.frontend_user_data
}