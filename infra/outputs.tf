output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.subnets.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "frontend_public_ip" {
  description = "Public IP of the frontend instance"
  value       = module.ec2.frontend_public_ip
}

output "frontend_instance_id" {
  description = "Instance ID of the frontend server"
  value       = module.ec2.frontend_instance_id
}

output "backend_private_ip" {
  description = "Private IP of the backend instance"
  value       = module.ec2.backend_private_ip
}

output "backend_instance_id" {
  description = "Instance ID of the backend server"
  value       = module.ec2.backend_instance_id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = module.nat.nat_gateway_public_ip
}

output "ssh_command_frontend" {
  description = "SSH command to connect to frontend instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.ec2.frontend_public_ip}"
}