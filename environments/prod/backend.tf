# Production Environment - Backend Configuration
# Remote state management with S3 and DynamoDB locking

terraform {
  backend "s3" {
    
    bucket         = "s3_eisai_prod" 
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock_prod"
   
  }
}

# Production State Management Best Practices:
# 1. Enable S3 bucket versioning (already done in setup)
# 2. Enable MFA delete on state bucket
# 3. Use separate AWS account for production
# 4. Restrict access to state bucket with IAM policies
# 5. Enable CloudTrail logging for state bucket access
# 6. Use different backend configuration from dev/staging
