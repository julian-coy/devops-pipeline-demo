# =============================================================================
# S3 BUCKETS FOR TERRAFORM REMOTE STATE
# =============================================================================
# Almacenan el state de Terraform en S3 (remote backend).
# Beneficios:
# - Estado compartido entre desarrolladores y CI/CD
# - Versionado: recuperar estados anteriores
# - Encriptación: protege datos sensibles
# - Locking con DynamoDB: evita conflictos concurrentes
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# DEV ENVIRONMENT STATE BUCKET
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "state_dev" {
  # Nombre único del bucket basado en project_name
  # AWS requiere nombres únicos globalmente
  bucket        = "${var.project_name}-terraform-state-dev"
  # force_destroy = true solo para demos; en prod usar false para protección
  force_destroy = true

  tags = {
    Name        = "Terraform State DEV"
    Environment = "dev"
  }
}

# Habilita versionado del state para recuperación de versiones anteriores
resource "aws_s3_bucket_versioning" "state_dev" {
  bucket = aws_s3_bucket.state_dev.id

  versioning_configuration {
    # Enabled: Mantiene histórico de versiones de objetos
    status = "Enabled"
  }
}

# Encriptación del lado del servidor (SSE) para datos en reposo
resource "aws_s3_bucket_server_side_encryption_configuration" "state_dev" {
  bucket = aws_s3_bucket.state_dev.id

  rule {
    apply_server_side_encryption_by_default {
      # AES256: Encriptación simétrica suficiente para la mayoría de casos
      # Alternativa: aws:kms para control más granular
      sse_algorithm = "AES256"
    }
  }
}

# Bloquea acceso público de forma preventiva
# Protege contra exposiciones accidentales de credenciales en el state
resource "aws_s3_bucket_public_access_block" "state_dev" {
  bucket = aws_s3_bucket.state_dev.id

  block_public_acls       = true  # Previene que ACLs públicas se agreguen
  block_public_policy     = true  # Previene que policies públicas se agreguen
  ignore_public_acls      = true  # Ignora ACLs públicas existentes
  restrict_public_buckets = true  # Previene acceso público incluso con credenciales
}

# ─────────────────────────────────────────────────────────────────────────────
# PROD ENVIRONMENT STATE BUCKET
# ─────────────────────────────────────────────────────────────────────────────
# Separado de DEV para aislamiento completo
# En producción, considerar force_destroy = false para protección adicional

resource "aws_s3_bucket" "state_prod" {
  bucket        = "${var.project_name}-terraform-state-prod"
  force_destroy = true

  tags = {
    Name        = "Terraform State PROD"
    Environment = "prod"
  }
}

resource "aws_s3_bucket_versioning" "state_prod" {
  bucket = aws_s3_bucket.state_prod.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_prod" {
  bucket = aws_s3_bucket.state_prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_prod" {
  bucket = aws_s3_bucket.state_prod.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
