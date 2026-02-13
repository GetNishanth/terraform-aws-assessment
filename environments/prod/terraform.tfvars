# Production Environment - Variable Values

aws_region   = "us-east-1"
environment  = "prod"
project_name = "terraform-assessment"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Network Settings
enable_nat_gateway = true
single_nat_gateway = false

# EC2 Configuration
instance_type    = "t3.small"
instance_count   = 2        
root_volume_size = 30

# S3 Configuration
log_bucket_name    = "eisai-dev-logs"
log_retention_days = 365
