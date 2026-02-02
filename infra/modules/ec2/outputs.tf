output "frontend_instance_id" {
  description = "ID of the frontend instance"
  value       = aws_instance.frontend.id
}

output "frontend_public_ip" {
  description = "Public IP of the frontend instance"
  value       = aws_instance.frontend.public_ip
}

output "frontend_private_ip" {
  description = "Private IP of the frontend instance"
  value       = aws_instance.frontend.private_ip
}

output "backend_instance_id" {
  description = "ID of the backend instance"
  value       = aws_instance.backend.id
}

output "backend_private_ip" {
  description = "Private IP of the backend instance"
  value       = aws_instance.backend.private_ip
}