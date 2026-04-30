variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "devops-demo"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "allowed_cidr_blocks" {
  description = "CIDRs con acceso HTTP/HTTPS. Restringir en producción real."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
