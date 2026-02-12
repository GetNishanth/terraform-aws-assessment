# Production Environment - Main Configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  common_tags          = local.common_tags
}

# S3 Module for Logs
module "s3_logs" {
  source = "../../modules/s3"

  bucket_name           = var.log_bucket_name
  log_retention_days    = var.log_retention_days
  enable_access_logging = true  # Enable for production
  common_tags           = local.common_tags
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_type      = var.instance_type
  instance_count     = var.instance_count
  root_volume_size   = var.root_volume_size
  log_bucket_name    = module.s3_logs.bucket_id
  log_bucket_arn     = module.s3_logs.bucket_arn
  common_tags        = local.common_tags

  depends_on = [module.s3_logs]
}
