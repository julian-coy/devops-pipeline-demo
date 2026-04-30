# Bootstrap Terraform Configuration

## Overview

El bootstrap crea la **infraestructura base** necesaria para el pipeline de CI/CD. Se ejecuta **UNA sola vez** desde tu máquina local con credenciales administrativas de AWS.

## What It Creates

| Resource | Purpose | Cost |
|----------|---------|------|
| S3 Bucket (DEV) | Remote state storage para DEV | ~$1/month |
| S3 Bucket (PROD) | Remote state storage para PROD | ~$1/month |
| DynamoDB Table | State locking (concurrency control) | Free |
| IAM User | GitHub Actions CI/CD credentials | Free |
| IAM Access Keys | API credentials para CI/CD | Free |
| IAM Policy | Least privilege permissions | Free |

## Quick Start

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

## Important: Save the Outputs

Después de `apply`, guarda estos valores (necesarios para GitHub Secrets):

```bash
terraform output access_key_id      # → AWS_ACCESS_KEY_ID
terraform output secret_access_key  # → AWS_SECRET_ACCESS_KEY
```

## Architecture Decisions

### ✅ Why S3 for Remote State?
- Global availability
- Native Terraform integration
- Versioning for rollback
- Server-side encryption

### ✅ Why DynamoDB for State Lock?
- Atomic operations guaranteed
- Prevents state corruption with concurrent applies
- Free tier compatible

### ✅ Why Separate DEV/PROD Buckets?
- Isolation: DEV failures don't affect PROD
- Granular permissions possible
- Independent disaster recovery

### ✅ Why IAM User with Least Privilege?
- Security: GitHub Actions doesn't need full access
- Isolation: compromised key has limited damage
- Compliance: follows least privilege principle

## Clean Up

```bash
terraform destroy
```

⚠️ **Nota**: Los buckets S3 se borrarán (force_destroy = true para demo).
