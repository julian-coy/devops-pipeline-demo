# =============================================================================
# OUTPUT VALUES
# =============================================================================
# Exporta valores críticos del bootstrap para usarlos en los siguientes pasos:
# - GitHub Secrets: Access keys para CI/CD
# - Backend configs: Nombres de buckets y tabla DynamoDB
# =============================================================================

output "access_key_id" {
  description = "AWS Access Key ID para GitHub Actions. GUARDA ESTO: necesario en GitHub Secrets como AWS_ACCESS_KEY_ID."
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true  # No se muestra en logs por seguridad
}

output "secret_access_key" {
  description = "AWS Secret Access Key para GitHub Actions. GUARDA ESTO: necesario en GitHub Secrets como AWS_SECRET_ACCESS_KEY."
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "iam_user" {
  description = "Nombre del usuario IAM creado para GitHub Actions."
  value       = aws_iam_user.github_actions.name
}

output "state_bucket_dev" {
  description = "Nombre del bucket S3 para remote state de DEV. Cópialo en terraform/environments/dev/backend.tf."
  value       = aws_s3_bucket.state_dev.bucket
}

output "state_bucket_prod" {
  description = "Nombre del bucket S3 para remote state de PROD. Cópialo en terraform/environments/prod/backend.tf."
  value       = aws_s3_bucket.state_prod.bucket
}

output "dynamodb_table" {
  description = "Nombre de la tabla DynamoDB para state locking. Úsalo en backend.tf de DEV y PROD."
  value       = aws_dynamodb_table.state_lock.name
}

output "bootstrap_summary" {
  description = "Resumen de los recursos creados por el bootstrap."
  value = {
    message = "✅ Bootstrap completado. Copia los valores anteriores a GitHub Secrets y backend.tf"
    region  = var.aws_region
    project = var.project_name
  }
}