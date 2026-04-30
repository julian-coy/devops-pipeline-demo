# =============================================================================
# BOOTSTRAP — TERRAFORM & PROVIDER CONFIG
# =============================================================================
# Se ejecuta UNA sola vez desde local con credenciales de administrador.
# Los recursos están en s3.tf, dynamodb.tf e iam.tf.
# =============================================================================

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
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
