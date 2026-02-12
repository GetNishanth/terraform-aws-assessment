# Production Environment - Outputs

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# EC2 Outputs
output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "ec2_private_ips" {
  description = "EC2 private IP addresses"
  value       = module.ec2.instance_private_ips
}

output "ec2_iam_role" {
  description = "EC2 IAM role name"
  value       = module.ec2.iam_role_name
}

# S3 Outputs
output "log_bucket_name" {
  description = "S3 log bucket name"
  value       = module.s3_logs.bucket_id
}

output "log_bucket_arn" {
  description = "S3 log bucket ARN"
  value       = module.s3_logs.bucket_arn
}

# Connection Instructions
output "connection_instructions" {
  description = "How to connect to EC2 instances"
  value       = <<-EOT
    PRODUCTION ENVIRONMENT - Access Restricted
    
    To connect to EC2 instances using AWS Systems Manager Session Manager:
    
    1. Ensure you have production AWS credentials configured
    2. Verify you have necessary IAM permissions
    3. Run: aws ssm start-session --target <INSTANCE_ID>
    
    Available instances:
    ${join("\n    ", [for id in module.ec2.instance_ids : "- ${id}"])}
    
    SECURITY NOTE:
    - All access is logged in CloudTrail
    - Session activity is recorded
    - Direct SSH access is disabled
    - Production access requires approval (implement via IAM policies)
  EOT
}
