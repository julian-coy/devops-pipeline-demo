# =============================================================================
# VERSIONING CONSTRAINTS
# =============================================================================
# Define versiones mínimas y máximas de Terraform y providers.
# Esto garantiza compatibilidad y evita cambios inesperados en comportamiento.
# =============================================================================

terraform {
  # Versión mínima de Terraform requerida para este proyecto
  required_version = ">= 1.0"

  required_providers {
    aws = {
      # Proveedor oficial de AWS mantenido por HashiCorp
      source  = "hashicorp/aws"
      # Versión 5.x: Última versión estable con soporte activo
      # ~> 5.0 significa: >= 5.0.0, < 6.0.0 (compatible semver)
      version = "~> 5.0"
    }
  }
}
