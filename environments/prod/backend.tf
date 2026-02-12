# Production Environment - Backend Configuration
# Remote state management with S3 and DynamoDB locking

terraform {
  backend "s3" {
    # IMPORTANT: Update these values with your actual S3 bucket and DynamoDB table
    # Use SEPARATE state from dev for isolation
    
    bucket         = "your-terraform-state-bucket"  # Replace with your bucket name
    key            = "prod/terraform.tfstate"       # Different key from dev
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Replace with your table name
    
    # PRODUCTION SECURITY: Enable MFA delete on state bucket
    # PRODUCTION SECURITY: Use IAM role for access, not access keys
    # role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformStateProdRole"
  }
}

# Production State Management Best Practices:
# 1. Enable S3 bucket versioning (already done in setup)
# 2. Enable MFA delete on state bucket
# 3. Use separate AWS account for production
# 4. Restrict access to state bucket with IAM policies
# 5. Enable CloudTrail logging for state bucket access
# 6. Use different backend configuration from dev/staging
