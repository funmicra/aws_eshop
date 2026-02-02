variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "candle-shop"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "192.168.33.0/24"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["192.168.33.0/26", "192.168.33.64/26"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["192.168.33.128/26", "192.168.33.192/26"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "candle-shop-key"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access (restrict to your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # CHANGE THIS TO YOUR IP!
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = ""
}

variable "backend_user_data" {
  description = "User data script for backend instance"
  type        = string
  default     = ""
}

variable "frontend_user_data" {
  description = "User data script for frontend instance"
  type        = string
  default     = ""
}