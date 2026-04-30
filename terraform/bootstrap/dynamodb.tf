# =============================================================================
# DYNAMODB TABLE FOR TERRAFORM STATE LOCKING
# =============================================================================
# Previene que múltiples terraform apply corran simultáneamente.
# Sin locking: 2+ usuarios haciendo apply → corrupción del state file.
# Terraform usa esta tabla automáticamente con backend S3.
# =============================================================================

resource "aws_dynamodb_table" "state_lock" {
  # Nombre de la tabla (debe coincidir en backend.tf de env)
  name         = "${var.project_name}-state-lock"
  # PAY_PER_REQUEST: Ideal para cargas impredecibles/bajo tráfico (free tier compatible)
  # PROVISIONED: Mejor para cargas predecibles y consistentes (requiere capacity units)
  billing_mode = "PAY_PER_REQUEST"
  # Hash key: Terraform usa "LockID" como convención estándar
  hash_key     = "LockID"

  # Esquema de atributos
  attribute {
    name = "LockID"
    type = "S"  # S = String, N = Number, B = Binary
  }

  # Time to Live: 60 segundos
  # Previene locks huérfanos si un apply se interrumpe abruptamente
  ttl {
    attribute_name = "Expiration"
    enabled        = true
  }

  tags = {
    Name = "Terraform State Lock"
  }
}
