# =============================================================================
# INPUT VARIABLES
# =============================================================================
# Variables de configuración que permiten personalizar el bootstrap.
# Valores por defecto optimizados para demo pero modificables.
# =============================================================================

variable "aws_region" {
  description = "Región AWS donde se crearán todos los recursos. us-east-1 recomendado para free tier."
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "La región debe ser válida (ej: us-east-1, eu-west-1)."
  }
}

variable "project_name" {
  description = "Nombre base del proyecto. Se usa como prefijo en todos los recursos AWS para evitar conflictos."
  type        = string
  default     = "devops-demo"
  
  validation {
    condition     = can(regex("^[a-z0-9-]{1,30}$", var.project_name))
    error_message = "El nombre debe: contener solo minúsculas, números y guiones, máximo 30 caracteres."
  }
}