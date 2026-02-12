# Production Environment - Variable Values
# This file contains production-specific configuration

aws_region   = "us-east-1"
environment  = "prod"
project_name = "terraform-assessment"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Network Settings
enable_nat_gateway = true
single_nat_gateway = false  # High Availability: NAT Gateway per AZ

# EC2 Configuration
instance_type    = "t3.small"  # Larger instance for production
instance_count   = 2           # Multiple instances for HA
root_volume_size = 30

# S3 Configuration
# IMPORTANT: Change this to a globally unique bucket name
log_bucket_name    = "my-terraform-prod-logs-12345"  # Replace with unique name
log_retention_days = 365  # Keep logs longer in production
