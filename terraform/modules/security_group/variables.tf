variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_cidr_blocks" {
  description = "CIDRs con acceso HTTP/HTTPS. En producción: IP del ALB o rango corporativo. Para demo: tu IP pública."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
