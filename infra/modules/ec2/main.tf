# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
  }
}

# Attach SSM policy for Session Manager access (more secure than SSH)
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy for logging
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Frontend Instance
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.frontend_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  
  user_data = var.frontend_user_data != "" ? var.frontend_user_data : templatefile("${path.module}/user_data_frontend.sh", {
    project_name = var.project_name
  })
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }
  
  monitoring = true
  
  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
    Role        = "frontend"
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
}

# Backend Instance
resource "aws_instance" "backend" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.backend_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  
  user_data = var.backend_user_data != "" ? var.backend_user_data : templatefile("${path.module}/user_data_backend.sh", {
    project_name = var.project_name
  })
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }
  
  monitoring = true
  
  tags = {
    Name        = "${var.project_name}-backend"
    Environment = var.environment
    Role        = "backend"
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
}

# Attach Backend to Target Group
resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = var.alb_target_group_arn
  target_id        = aws_instance.backend.id
  port             = 80
}

# CloudWatch Alarms for Frontend
resource "aws_cloudwatch_metric_alarm" "frontend_cpu" {
  alarm_name          = "${var.project_name}-frontend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors frontend instance CPU utilization"
  
  dimensions = {
    InstanceId = aws_instance.frontend.id
  }
}

# CloudWatch Alarms for Backend
resource "aws_cloudwatch_metric_alarm" "backend_cpu" {
  alarm_name          = "${var.project_name}-backend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors backend instance CPU utilization"
  
  dimensions = {
    InstanceId = aws_instance.backend.id
  }
}