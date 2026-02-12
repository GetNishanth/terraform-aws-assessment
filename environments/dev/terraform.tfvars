# Development Environment - Variable Values
# This file contains environment-specific configuration

aws_region   = "us-east-1"
environment  = "dev"
project_name = "terraform-assessment"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Network Settings
enable_nat_gateway = true
single_nat_gateway = true  # Cost optimization: use single NAT for dev

# EC2 Configuration
instance_type    = "t3.micro"
instance_count   = 1
root_volume_size = 20

# S3 Configuration
# IMPORTANT: Change this to a globally unique bucket name
log_bucket_name    = "my-terraform-dev-logs-12345"  # Replace with unique name
log_retention_days = 90
