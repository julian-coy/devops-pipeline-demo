resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg-web-${var.environment}"
  description = "Security group para el servidor web Nginx"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 22 cerrado — acceso via SSM Session Manager (Zero Trust)

  tags = {
    Name        = "${var.project_name}-sg-web-${var.environment}"
    Environment = var.environment
  }
}
