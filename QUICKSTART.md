# Quick Start Guide

This guide will help you deploy the infrastructure quickly.

## Prerequisites Checklist

- [ ] AWS account with appropriate permissions
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Terraform 1.5+ installed (`terraform version`)
- [ ] Git installed (to clone/manage repository)

## Step 1: Initial Setup (First Time Only)

### Create Remote State Backend

```bash
# 1. Create S3 bucket for state
aws s3 mb s3://YOUR-UNIQUE-BUCKET-NAME --region us-east-1

# 2. Enable versioning
aws s3api put-bucket-versioning \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --versioning-configuration Status=Enabled

# 3. Enable encryption
aws s3api put-bucket-encryption \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Step 2: Configure Your Environment

### For Development

```bash
# Navigate to dev environment
cd environments/dev

# 1. Edit backend.tf and update bucket name
# Replace "your-terraform-state-bucket" with your actual bucket

# 2. Edit terraform.tfvars
# Replace "my-terraform-dev-logs-12345" with a globally unique S3 bucket name
```

### For Production

```bash
# Navigate to prod environment
cd environments/prod

# 1. Edit backend.tf and update bucket name
# 2. Edit terraform.tfvars and update S3 bucket name
```

## Step 3: Deploy Infrastructure

### Development Environment

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output
```

### Production Environment

```bash
cd environments/prod

# Initialize Terraform
terraform init

# Create workspace (optional but recommended)
terraform workspace new prod

# Preview changes
terraform plan

# Apply changes (requires manual approval)
terraform apply

# View outputs
terraform output
```

## Step 4: Verify Deployment

### Check Resources in AWS Console

1. **VPC**: Navigate to VPC Dashboard
   - Verify VPC exists (10.0.0.0/16)
   - Check 2 public and 2 private subnets
   - Verify Internet Gateway and NAT Gateway

2. **EC2**: Navigate to EC2 Dashboard
   - Verify instance(s) running in private subnet
   - Check IAM role is attached
   - Verify security group

3. **S3**: Navigate to S3
   - Verify log bucket exists
   - Check encryption is enabled
   - Verify versioning is enabled

### Connect to EC2 Instance

```bash
# Get instance ID from output
terraform output ec2_instance_ids

# Connect using SSM Session Manager
aws ssm start-session --target i-xxxxxxxxxxxxx

# Once connected, verify user data script ran
cat /var/log/user-data.log
ls -la /opt/app/logs/
```

## Common Commands Reference

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Refresh state
terraform refresh

# Create plan file
terraform plan -out=tfplan

# Apply specific plan
terraform apply tfplan

# Destroy infrastructure (CAREFUL!)
terraform destroy
```

## Troubleshooting

### Error: "Error locking state"
**Solution**: Verify DynamoDB table exists and has correct permissions

### Error: "Backend configuration changed"
**Solution**: Run `terraform init -reconfigure`

### Error: "BucketAlreadyExists"
**Solution**: S3 bucket names must be globally unique. Change the name in terraform.tfvars

### Error: "UnauthorizedOperation"
**Solution**: Verify AWS credentials have necessary IAM permissions

### Can't connect to EC2 via SSM
**Solution**: 
1. Verify instance has IAM role attached
2. Check Systems Manager agent is running
3. Verify security group allows HTTPS (443)
4. Ensure instance can reach internet via NAT Gateway

## Cost Estimation

**Development (single NAT)**: ~$40-50/month
**Production (dual NAT)**: ~$70-80/month base

To reduce costs in dev:
- Stop EC2 instances when not in use
- Use t3.micro (included in free tier for new accounts)
- Consider removing NAT Gateway for testing (breaks internet for private subnet)

## Next Steps

After successful deployment:

1. Set up monitoring (CloudWatch dashboards)
2. Configure alerts (CloudWatch alarms)
3. Implement CI/CD pipeline
4. Add auto-scaling
5. Set up load balancer
6. Configure backups
7. Implement disaster recovery

## Clean Up

When you're done testing:

```bash
# Destroy development environment
cd environments/dev
terraform destroy

# Destroy production environment
cd environments/prod
terraform destroy

# Optionally delete state bucket and DynamoDB table
aws s3 rb s3://YOUR-BUCKET-NAME --force
aws dynamodb delete-table --table-name terraform-state-lock
```

## Getting Help

- Check the main README.md for detailed documentation
- Review AWS provider documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform best practices: https://www.terraform-best-practices.com/

## Important Security Notes

1. **Never commit**: 
   - AWS credentials
   - *.tfvars files with sensitive data
   - State files
   - Private keys

2. **Always use**:
   - IAM roles instead of access keys where possible
   - Encryption for state and data
   - MFA for production access
   - Least privilege IAM policies

3. **Enable**:
   - CloudTrail for audit logging
   - VPC Flow Logs
   - Config for compliance
   - GuardDuty for threat detection
