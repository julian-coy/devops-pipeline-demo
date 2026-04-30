# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
# Configura la conexión con AWS y valores por defecto para todos los recursos.
# =============================================================================

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "devops-demo"
      ManagedBy = "Terraform"
    }
  }
}
