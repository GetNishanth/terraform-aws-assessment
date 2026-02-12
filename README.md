# Terraform AWS Infrastructure Assessment

## Overview
This repository contains a production-ready Terraform configuration that provisions AWS infrastructure including VPC, subnets, EC2 instances, and S3 storage. The solution demonstrates infrastructure-as-code best practices including modularity, environment separation, and remote state management.

## Architecture

### Network Layout
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnets**: 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b)
- **Private Subnets**: 10.0.10.0/24 (AZ-a), 10.0.11.0/24 (AZ-b)
- **Internet Gateway**: Attached to VPC for public subnet internet access
- **NAT Gateway**: Enables private subnet outbound internet (optional for cost)

### Components
- **VPC Module**: Reusable networking foundation
- **EC2 Module**: Application instances with IAM roles
- **S3 Module**: Log storage with encryption and versioning
- **Remote Backend**: S3 + DynamoDB for state management and locking

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** v1.5+ installed
4. **S3 Bucket** for remote state (manual creation required first time)
5. **DynamoDB Table** for state locking (manual creation required first time)

### Initial Setup (One-time)

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning on state bucket
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Project Structure

```
.
├── README.md
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── user-data.sh
    └── s3/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Usage

### Deploy Development Environment

```bash
# Navigate to dev environment
cd environments/dev

# Initialize Terraform (downloads providers and modules)
terraform init

# Review planned changes
terraform plan

# Apply infrastructure changes
terraform apply

# View outputs
terraform output
```

### Deploy Production Environment

```bash
# Navigate to prod environment
cd environments/prod

# Update backend.tf with your actual bucket name
# Update terraform.tfvars with production values

# Initialize Terraform
terraform init

# Create workspace for additional isolation (optional)
terraform workspace new prod

# Review changes carefully
terraform plan

# Apply with approval requirement
terraform apply

# For production, consider using auto-approve only in CI/CD
# terraform apply -auto-approve  # NOT recommended for manual prod deploys
```

### Destroy Resources (Use with Caution!)

```bash
# Destroy dev environment
cd environments/dev
terraform destroy

# For production, enable deletion protection first
```

## Design Choices & Trade-offs

### 1. **Module Design**
- **Choice**: Created separate modules for VPC, EC2, and S3
- **Rationale**: Promotes reusability and separation of concerns
- **Trade-off**: Slightly more complex for small projects, but scales well

### 2. **Network Architecture**
- **Choice**: 2 public + 2 private subnets across 2 AZs
- **Rationale**: High availability and security best practices
- **Trade-off**: NAT Gateway costs (~$32/month per AZ) - dev uses single NAT for cost savings

### 3. **State Management**
- **Choice**: Remote backend with S3 + DynamoDB locking
- **Rationale**: Team collaboration, state integrity, and concurrency control
- **Trade-off**: Requires manual backend setup before first run

### 4. **Tagging Strategy**
- **Choice**: Consistent tags (Environment, ManagedBy, Project)
- **Rationale**: Cost allocation, resource tracking, automation
- **Trade-off**: Requires discipline to maintain across all resources

### 5. **EC2 in Private Subnet**
- **Choice**: EC2 instances in private subnets with IAM role
- **Rationale**: Security - no direct internet exposure, uses NAT for outbound
- **Trade-off**: Requires bastion host or SSM for SSH access

## Part 3 – Scenario Answers

### Q1: How do you handle infrastructure drift?

**Drift** occurs when actual infrastructure differs from Terraform state.

**Detection:**
```bash
# Run terraform plan regularly to detect drift
terraform plan -out=drift-check.tfplan

# For automated drift detection
# Use tools like Terraform Cloud, AWS Config, or scheduled CI/CD jobs
```

**Prevention:**
- Restrict console/CLI access to infrastructure
- Use AWS Organizations SCPs to prevent manual changes
- Implement pull request reviews for all Terraform changes
- Enable CloudTrail for audit logging

**Remediation:**
```bash
# Option 1: Apply Terraform to fix drift
terraform apply

# Option 2: Import manual changes into state
terraform import aws_instance.app i-1234567890abcdef0

# Option 3: Refresh state and update code
terraform refresh
# Then update .tf files to match actual state
```

### Q2: How would you import an existing VPC into Terraform?

**Step-by-step import process:**

```bash
# 1. Write the resource block in your .tf file
# vpc.tf
resource "aws_vpc" "existing" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "existing-vpc"
  }
}

# 2. Import the VPC using its ID
terraform import aws_vpc.existing vpc-0a1b2c3d4e5f6g7h8

# 3. Run terraform plan to see any differences
terraform plan

# 4. Update the resource block to match actual configuration
# Add missing attributes like enable_dns_hostnames, etc.

# 5. Verify no changes needed
terraform plan  # Should show "No changes"
```

**For bulk imports:**
```bash
# Use terraformer or former2 tools to generate Terraform code
# from existing AWS infrastructure

# Example with terraformer
terraformer import aws --resources=vpc,subnet,igw --regions=us-east-1
```

### Q3: How do you prevent accidental deletion of prod infrastructure?

**Multiple protection layers:**

**1. Lifecycle Prevention:**
```hcl
resource "aws_instance" "prod_app" {
  # ... other config ...
  
  lifecycle {
    prevent_destroy = true  # Terraform will error if trying to destroy
  }
}
```

**2. Resource Deletion Protection:**
```hcl
resource "aws_db_instance" "production" {
  deletion_protection = true  # AWS-level protection
}
```

**3. Workspace Isolation:**
```bash
# Use separate workspaces
terraform workspace new prod
terraform workspace select prod
```

**4. Backend State Protection:**
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    
    # Enable versioning and MFA delete on the bucket
  }
}
```

**5. CI/CD Safeguards:**
- Require manual approval for production apply
- Use `terraform plan` artifacts
- Implement CODEOWNERS for production tfvars
- Restrict production AWS credentials to CI/CD only

**6. IAM Policies:**
```json
{
  "Statement": [{
    "Effect": "Deny",
    "Action": [
      "ec2:TerminateInstances",
      "rds:DeleteDBInstance"
    ],
    "Resource": "*",
    "Condition": {
      "StringEquals": {
        "aws:RequestedRegion": "us-east-1",
        "ec2:ResourceTag/Environment": "production"
      }
    }
  }]
}
```

## Part 4 – Production Readiness

### Terraform in CI/CD Pipeline

**Typical GitOps Workflow:**

```yaml
# Example GitHub Actions workflow
name: Terraform CI/CD

on:
  pull_request:
    paths:
      - 'environments/prod/**'
  push:
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
      
      - name: Terraform Init
        run: terraform init
        working-directory: environments/prod
      
      - name: Terraform Validate
        run: terraform validate
        working-directory: environments/prod
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: environments/prod
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Terraform Apply (on merge to main)
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan
        working-directory: environments/prod
```

**Best Practices:**
- Run `terraform plan` on every PR
- Post plan output as PR comment
- Require manual approval for `apply` in production
- Use OIDC for AWS authentication (no static keys)
- Store state in S3 with versioning
- Use separate AWS accounts for dev/prod

### Secrets Management Approach

**1. AWS Secrets Manager Integration:**
```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "app" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

**2. Environment Variables:**
```bash
# Never commit credentials
export TF_VAR_db_password="secret-value"
terraform apply
```

**3. Variable Files (for non-secrets):**
```hcl
# terraform.tfvars (committed - no secrets!)
environment = "prod"
instance_type = "t3.medium"

# secrets.tfvars (NEVER commit - add to .gitignore!)
db_password = "actual-secret"

# Usage
terraform apply -var-file="terraform.tfvars" -var-file="secrets.tfvars"
```

**4. IAM Roles (Preferred for AWS resources):**
```hcl
# No secrets in code at all
resource "aws_iam_role" "ec2_app" {
  name = "ec2-app-role"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
```

**5. .gitignore essentials:**
```
# .gitignore
*.tfvars
!terraform.tfvars.example
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
secrets.auto.tfvars
```

### Version Pinning & Upgrade Strategy

**1. Provider Version Constraints:**
```hcl
# versions.tf
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Allow 5.x updates, not 6.0
    }
  }
}
```

**Version Constraint Operators:**
- `= 1.5.0` - Exact version only
- `>= 1.5.0` - Version 1.5.0 or newer
- `~> 1.5` - Any version 1.x (1.5, 1.6, not 2.0)
- `~> 1.5.0` - Any version 1.5.x (1.5.1, 1.5.2, not 1.6)

**2. Module Version Pinning:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"  # Pin exact version for stability
}
```

**3. Upgrade Strategy:**

```bash
# Step 1: Review changelog
# Check provider/module release notes for breaking changes

# Step 2: Update in dev first
cd environments/dev
# Update version constraint in versions.tf
terraform init -upgrade

# Step 3: Test thoroughly
terraform plan
terraform apply
# Run application tests

# Step 4: Promote to prod
cd environments/prod
# Update version constraint
terraform init -upgrade
terraform plan
# Review plan carefully
terraform apply

# Step 5: Lock file
git add .terraform.lock.hcl
git commit -m "chore: upgrade AWS provider to 5.0.1"
```

**4. Dependabot/Renovate for automation:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "terraform"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "devops-team"
```

## Assumptions

1. **AWS Region**: us-east-1 (easily configurable via variables)
2. **Cost Optimization**: Dev environment uses single NAT Gateway
3. **Access**: EC2 instances use Systems Manager Session Manager (no SSH keys)
4. **Logging**: S3 bucket has versioning and encryption enabled
5. **Network**: Private subnets have outbound internet via NAT
6. **State**: S3 bucket and DynamoDB table exist before first run

## Common Commands

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# View current state
terraform show

# List resources in state
terraform state list

# View specific resource
terraform state show aws_vpc.main

# Remove resource from state (doesn't delete actual resource)
terraform state rm aws_instance.old_app

# Refresh state from actual infrastructure
terraform refresh

# View outputs
terraform output

# Create a plan file for review
terraform plan -out=tfplan

# Apply a specific plan
terraform apply tfplan

# Target specific resource
terraform apply -target=module.vpc

# Replace a resource (taint + apply)
terraform apply -replace=aws_instance.app
```

## Security Best Practices Implemented

✅ No hardcoded credentials or account IDs  
✅ IAM roles for EC2 (not access keys)  
✅ Private subnets for compute resources  
✅ S3 bucket encryption enabled  
✅ S3 versioning for state and logs  
✅ DynamoDB state locking  
✅ Security groups with minimal required access  
✅ Consistent tagging for governance  
✅ Remote state with encryption  

## Cost Estimation (Monthly, us-east-1)

**Development Environment:**
- VPC: Free
- NAT Gateway: ~$32
- EC2 t3.micro: ~$7
- S3 Storage: ~$1-5
- **Total: ~$40-45/month**

**Production Environment:**
- VPC: Free
- NAT Gateway (2 AZs): ~$64
- EC2 instances: Variable
- S3 Storage: Variable
- **Total: ~$70+ base cost/month**

## Troubleshooting

**Issue**: "Error locking state"  
**Solution**: Check DynamoDB table exists and Terraform has permissions

**Issue**: "Backend configuration changed"  
**Solution**: Run `terraform init -reconfigure`

**Issue**: "Resource already exists"  
**Solution**: Import existing resource or use `terraform import`

**Issue**: "Insufficient permissions"  
**Solution**: Verify IAM policies allow required actions

## Next Steps

- [ ] Set up CI/CD pipeline
- [ ] Add monitoring (CloudWatch, alerts)
- [ ] Implement auto-scaling
- [ ] Add application load balancer
- [ ] Configure VPC Flow Logs
- [ ] Implement backup strategy
- [ ] Add WAF for security
- [ ] Set up cross-region replication

## Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**Author**: [Your Name]  
**Last Updated**: February 2026  
**License**: MIT
