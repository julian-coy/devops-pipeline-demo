terraform {
  required_version = ">= 1.0"
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
      Project     = var.project_name
      Environment = "prod"
      ManagedBy   = "Terraform"
      Pipeline    = "GitHub Actions"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name      = var.project_name
  environment       = "prod"
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  availability_zone = var.availability_zone
}

module "security_group" {
  source = "../../modules/security_group"

  project_name        = var.project_name
  environment         = "prod"
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

module "ec2" {
  source = "../../modules/ec2"

  project_name      = var.project_name
  environment       = "prod"
  instance_type     = var.instance_type
  subnet_id         = module.vpc.subnet_id
  security_group_id = module.security_group.security_group_id
  app_content       = file("${path.root}/../../../app/index.html")
}
