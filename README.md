# Candle-Shop Infrastructure - Terraform Configuration

This Terraform configuration deploys a complete, secure, and production-ready infrastructure on AWS for the Candle-Shop application.

## Architecture Overview

```
Internet
    │
    ▼
[Application Load Balancer]
    │
    ├─► [Public Subnet A] ──► [Frontend EC2]
    │   (192.168.33.0/26)
    │
    ├─► [Public Subnet B]
    │   (192.168.33.64/26)
    │
    ├─► [NAT Gateway]
    │
    └─► [Internet Gateway]

Private Network
    │
    ├─► [Private Subnet A] ──► [Backend EC2]
    │   (192.168.33.128/26)
    │
    └─► [Private Subnet B]
        (192.168.33.192/26)
```

## Features

### Security
- ✅ VPC with public and private subnets across 2 AZs
- ✅ Security groups with least privilege access
- ✅ NAT Gateway for private subnet internet access
- ✅ IMDSv2 enforced on EC2 instances
- ✅ Encrypted EBS volumes
- ✅ VPC Flow Logs for network monitoring
- ✅ ALB access logs (optional)
- ✅ CloudWatch monitoring and alarms
- ✅ IAM roles with SSM for secure access (no SSH required)

### High Availability
- ✅ Multi-AZ deployment
- ✅ Application Load Balancer
- ✅ Health checks configured
- ✅ Auto-healing with CloudWatch alarms

### Monitoring
- ✅ CloudWatch Logs for application logs
- ✅ CloudWatch Metrics for CPU, memory, disk
- ✅ CloudWatch Alarms for high CPU usage
- ✅ VPC Flow Logs

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **SSH Key Pair** created in AWS (named `candle-shop-key` or update the variable)

## Project Structure

```
.
├── ansible
│   ├── deploy_wordpress.yml
│   └── inventory
│       └── generate_inventory.py
├── infra
│   ├── envs
│   │   ├── dev.tfvars
│   │   ├── prod.tfvars
│   │   └── terraform.tfvars.example
│   ├── locals.tf
│   ├── main.tf
│   ├── modules
│   │   ├── alb
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── ec2
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── user_data_backend.sh
│   │   │   ├── user_data_frontend.sh
│   │   │   └── variables.tf
│   │   ├── nat
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── route_tables
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── security
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── subnets
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   └── vpc
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   ├── variables.tf
│   └── versions.tf
├── Jenkinsfile
└── README.md
```

## Deployment Steps

### 1. Clone and Configure

```bash
# Navigate to project directory
cd candle-shop-terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars
```

**IMPORTANT**: Update `allowed_ssh_cidr` in `terraform.tfvars` to your IP address!

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

Review the resources that will be created. You should see approximately 30+ resources.

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. The deployment takes approximately 5-10 minutes.

### 5. Get Outputs

```bash
terraform output
```

You'll see:
- ALB DNS name
- Frontend public IP
- Backend private IP
- VPC and subnet IDs

## Post-Deployment

### Access Your Application

**Via Load Balancer:**
```bash
# Get the ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS
```

**Via Frontend Instance:**
```bash
# Get the frontend public IP
FRONTEND_IP=$(terraform output -raw frontend_public_ip)
curl http://$FRONTEND_IP
```

### SSH Access to Frontend

```bash
# Traditional SSH
ssh -i mini-saas-key.pem ec2-user@$(terraform output -raw frontend_public_ip)

# Or use AWS Session Manager (more secure, no key required)
aws ssm start-session --target $(terraform output -raw frontend_instance_id)
```

### Access Backend from Frontend

```bash
# SSH to frontend first, then:
ssh ec2-user@$(terraform output -raw backend_private_ip)
```

### View Logs

```bash
# CloudWatch Logs
aws logs tail /${PROJECT_NAME}/frontend/nginx/access --follow
aws logs tail /${PROJECT_NAME}/backend/application --follow
```

## Security Best Practices Implemented

1. **Network Segmentation**: Public and private subnets
2. **Least Privilege**: Security groups only allow necessary traffic
3. **Encryption**: EBS volumes encrypted at rest
4. **Monitoring**: VPC Flow Logs, CloudWatch Logs and Metrics
5. **IMDSv2**: Enforced on all EC2 instances
6. **No Hardcoded Secrets**: Use AWS Secrets Manager or Parameter Store
7. **Session Manager**: Alternative to SSH for secure access
8. **Automatic Updates**: Configured via dnf-automatic

## Customization

### Add HTTPS Support

1. Request an ACM certificate for your domain
2. Update `terraform.tfvars`:
   ```hcl
   certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/xxxxx"
   ```
3. Apply changes: `terraform apply`

### Change Instance Types

Update in `terraform.tfvars`:
```hcl
instance_type = "t3.small"  # or t3.medium, etc.
```

### Add Auto Scaling

Create a new module for Auto Scaling Groups to replace single EC2 instances.

### Add RDS Database

1. Create a new `rds` module
2. Use the `db_sg` security group from the security module
3. Place RDS in private subnets

## Cost Optimization

Current estimated monthly cost (us-east-1, may vary by region):
- EC2 (2x t3.micro): ~$15
- ALB: ~$16
- NAT Gateway: ~$32
- Data Transfer: ~$5-10
- **Total: ~$68-73/month**

### Reduce Costs:
1. Use a single NAT Gateway (already configured)
2. Stop instances when not in use
3. Use reserved instances for production
4. Consider NAT instances instead of NAT Gateway for dev/test

## Troubleshooting

### Instances not healthy in target group?

```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids $(terraform output -raw backend_instance_id)

# Check target health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)

# SSH to instance and check logs
sudo systemctl status backend-app
sudo journalctl -u backend-app -f
```

### Cannot connect to instances?

1. Verify security group rules
2. Check NACL rules (default allows all)
3. Verify route tables
4. Check instance system logs: `aws ec2 get-console-output --instance-id <id>`

### ALB returns 503?

- Backend instance not healthy
- Target group misconfigured
- Application not listening on port 80

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will remove all resources and stop billing.

## License

This configuration is provided as-is for the Candle Shop project.