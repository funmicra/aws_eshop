variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for frontend instance"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for backend instance"
  type        = string
}

variable "frontend_sg_id" {
  description = "Security group ID for frontend instance"
  type        = string
}

variable "backend_sg_id" {
  description = "Security group ID for backend instance"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "frontend_user_data" {
  description = "User data script for frontend instance"
  type        = string
  default     = ""
}

variable "backend_user_data" {
  description = "User data script for backend instance"
  type        = string
  default     = ""
}