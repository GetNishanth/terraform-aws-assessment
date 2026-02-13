# Development Environment - Backend Configuration
# Remote state management with S3 and DynamoDB locking

terraform {
  backend "s3" {
    
    bucket         = "s3_eisai_dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock_dev"
    
  }
}

# Instructions for first-time setup:
# 1. Create S3 bucket: aws s3 mb s3://your-terraform-state-bucket --region us-east-1
# 2. Enable versioning: aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
# 3. Create DynamoDB table: aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
# 4. Update the bucket and table names above
# 5. Run: terraform init