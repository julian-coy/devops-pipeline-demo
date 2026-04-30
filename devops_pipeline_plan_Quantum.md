# 🚀 DevOps Pipeline Demo — Plan de Ejecución
> **Objetivo:** Diseñar e implementar un pipeline profesional que demuestre seniority técnico
> **Tiempo disponible:** ~9 horas
> **Entrega:** Video explicativo + código Terraform + diagrama

---

## 📋 Resumen de lo que vas a construir

```
GitHub (develop/main)
    └── GitHub Actions
          ├── fmt + validate + tfsec + plan
          ├── apply automático → DEV
          └── manual approval → apply → PROD
                    └── AWS
                          ├── IAM Role (least privilege)
                          ├── S3 (remote state dev + prod)
                          ├── DynamoDB (state locking)
                          ├── SSM Parameter Store (secrets)
                          └── VPC → Subnet → EC2 t2.micro (Nginx)
```

---

## ⏱️ Cronograma

| Hora | Actividad | Duración |
|------|-----------|----------|
| 4:20 - 4:50 | Diagrama en diagrams.net | 30 min |
| 4:50 - 5:10 | Estructura del repo local | 20 min |
| 5:10 - 5:40 | Bootstrap con Terraform (S3 + DynamoDB + IAM) | 30 min |
| 5:40 - 7:10 | Módulos Terraform (VPC + EC2 + SG) | 1h 30min |
| 7:10 - 7:30 | App de ejemplo (Nginx + index.html) | 20 min |
| 7:30 - 8:30 | GitHub Actions workflows | 1h |
| 8:30 - 9:00 | Subir a GitHub + configurar secrets | 30 min |
| 9:00 - 9:45 | Pruebas y verificación | 45 min |
| 9:45 - 10:45 | Grabar el video | 1h |
| 10:45 - 11:00 | Buffer para correcciones | 15 min |

---

## 📁 Estructura del repositorio

```
devops-pipeline-demo/
├── terraform.tf                    # ✅ Constraints globales + provider config
├── providers.tf                    # ✅ Configuración global del provider AWS
├── README.md                       # ✅ Documentación completa del PROYECTO
├── app/
│   └── index.html                  # App de ejemplo con Nginx
├── terraform/
│   ├── bootstrap/                  # Infra base (separa por responsabilidad)
│   │   ├── s3.tf                   # Buckets S3 para state (DEV + PROD)
│   │   ├── dynamodb.tf             # DynamoDB para state locking
│   │   ├── iam.tf                  # IAM user, keys, policy (least privilege)
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md               # Docs específicas del bootstrap
│   ├── modules/
│   │   ├── vpc/                    # Módulo reutilizable de VPC
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ec2/                    # Módulo reutilizable de EC2
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── security_group/         # Módulo reutilizable de SG
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── dev/                    # Ambiente DEV
│       │   ├── main.tf             # Llama los módulos
│       │   ├── variables.tf
│       │   ├── terraform.tfvars    # Valores de DEV
│       │   ├── backend.tf          # Remote state DEV
│       │   └── outputs.tf
│       └── prod/                   # Ambiente PROD
│           ├── main.tf
│           ├── variables.tf
│           ├── terraform.tfvars    # Valores de PROD
│           ├── backend.tf          # Apunta al S3 de PROD
│           └── outputs.tf
└── .github/
    └── workflows/
        ├── terraform-dev.yml       # Pipeline DEV (push a develop)
        └── terraform-prod.yml      # Pipeline PROD (push a main)
```

---

## 🔧 PASO 1 — Diagrama en diagrams.net (30 min)

### Cómo importar el XML:
1. Ve a **app.diagrams.net**
2. Click en **Extras → Edit Diagram**
3. Borra el contenido existente
4. Pega el XML del archivo `devops_pipeline.xml`
5. Click **OK**

### Para activar íconos AWS:
1. En el buscador de shapes escribe `aws`
2. Click en **"AWS 2026 (Abrir biblioteca)"**
3. Los íconos aparecen en el panel izquierdo

### Lo que debe mostrar el diagrama:
```
GitHub ──────► GitHub Actions ──────► AWS Shared Resources
(develop)      (7 pasos pipeline)     (IAM + S3 + DynamoDB + SSM)
(main)                                      │           │
                                            ▼           ▼
                                        DEV VPC     PROD VPC
                                        EC2+Nginx   EC2+Nginx
                                        (auto)      (manual)
                                            │           │
                                            └─────┬─────┘
                                                  ▼
                                            CloudWatch
                                        (logs + alarms + SNS)
```

---

## 🔧 PASO 2 — Crear estructura local (20 min)

```bash
# En WSL
mkdir devops-pipeline-demo
cd devops-pipeline-demo
git init
git checkout -b develop

# Crear estructura de directorios
mkdir -p app
mkdir -p terraform/bootstrap
mkdir -p terraform/modules/{vpc,ec2,security_group}
mkdir -p terraform/environments/{dev,prod}
mkdir -p .github/workflows

echo "# DevOps Pipeline Demo" > README.md
```

### .gitignore a crear:
```gitignore
# Terraform
*.tfstate
*.tfstate.backup
*.tfstate.lock.info
.terraform/
.terraform.lock.hcl
*.tfvars
!terraform.tfvars.example

# Credenciales — NUNCA en el repo
*.pem
*.key
.env
```

---

## 🔧 PASO 3 — Bootstrap con Terraform (30 min)

> ⚠️ Este paso se corre UNA sola vez desde local con tus credenciales de AWS.
> Crea la infraestructura necesaria para el remote state y el IAM user del pipeline.

### ✅ Estructura profesional implementada:
```
terraform/bootstrap/
├── s3.tf              # Buckets S3 para state (DEV + PROD)
├── dynamodb.tf        # DynamoDB para state locking
├── iam.tf             # IAM user, keys, policy (least privilege)
├── variables.tf       # Variables de configuración
├── outputs.tf         # Outputs para GitHub Secrets
└── README.md          # Documentación específica
```

Los archivos ya están creados con comentarios detallados y best practices aplicadas.

### terraform/bootstrap/main.tf
```hcl
# Bootstrap — crea los recursos necesarios para el pipeline
# Se corre UNA vez y NO se vuelve a tocar

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── S3 BUCKET PARA STATE DE DEV ─────────────────────────────
resource "aws_s3_bucket" "state_dev" {
  bucket        = "${var.project_name}-terraform-state-dev"
  force_destroy = true # Solo para pruebas — en prod usar false

  tags = {
    Name        = "Terraform State DEV"
    Environment = "dev"
    ManagedBy   = "Terraform Bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "state_dev" {
  bucket = aws_s3_bucket.state_dev.id
  versioning_configuration {
    status = "Enabled" # Permite recuperar estados anteriores
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_dev" {
  bucket = aws_s3_bucket.state_dev.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_dev" {
  bucket                  = aws_s3_bucket.state_dev.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── S3 BUCKET PARA STATE DE PROD ────────────────────────────
resource "aws_s3_bucket" "state_prod" {
  bucket        = "${var.project_name}-terraform-state-prod"
  force_destroy = true

  tags = {
    Name        = "Terraform State PROD"
    Environment = "prod"
    ManagedBy   = "Terraform Bootstrap"
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
  bucket                  = aws_s3_bucket.state_prod.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── DYNAMODB PARA STATE LOCKING ─────────────────────────────
# Evita que dos apply corran al mismo tiempo y corrompan el state
resource "aws_dynamodb_table" "state_lock" {
  name         = "${var.project_name}-state-lock"
  billing_mode = "PAY_PER_REQUEST" # Free tier compatible
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform State Lock"
    ManagedBy = "Terraform Bootstrap"
  }
}

# ─── IAM USER PARA GITHUB ACTIONS ────────────────────────────
# Least privilege — solo puede gestionar los recursos necesarios
resource "aws_iam_user" "github_actions" {
  name = "${var.project_name}-github-actions"

  tags = {
    Name      = "GitHub Actions Deploy User"
    ManagedBy = "Terraform Bootstrap"
  }
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# Política con mínimo privilegio necesario para el pipeline
resource "aws_iam_user_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permisos para leer/escribir el Terraform state en S3
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.state_dev.arn,
          "${aws_s3_bucket.state_dev.arn}/*",
          aws_s3_bucket.state_prod.arn,
          "${aws_s3_bucket.state_prod.arn}/*"
        ]
      },
      {
        # Permisos para el state locking en DynamoDB
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.state_lock.arn
      },
      {
        # Permisos para gestionar VPC, EC2, Security Groups
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}
```

### terraform/bootstrap/variables.tf
```hcl
variable "aws_region" {
  description = "Región AWS para el bootstrap"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto — se usa como prefijo en los recursos"
  type        = string
  default     = "devops-demo"
}
```

### terraform/bootstrap/outputs.tf
```hcl
# Estos outputs los necesitas para configurar GitHub Secrets y los backends

output "access_key_id" {
  description = "AWS Access Key ID para GitHub Actions — guárdalo en GitHub Secrets"
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true
}

output "secret_access_key" {
  description = "AWS Secret Access Key para GitHub Actions — guárdalo en GitHub Secrets"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "state_bucket_dev" {
  description = "Nombre del bucket S3 para el state de DEV"
  value       = aws_s3_bucket.state_dev.bucket
}

output "state_bucket_prod" {
  description = "Nombre del bucket S3 para el state de PROD"
  value       = aws_s3_bucket.state_prod.bucket
}

output "dynamodb_table" {
  description = "Nombre de la tabla DynamoDB para state locking"
  value       = aws_dynamodb_table.state_lock.name
}
```

### Comandos para correr el bootstrap:
```bash
cd terraform/bootstrap

# Inicializar (state local — solo para el bootstrap)
terraform init

# Ver qué va a crear
terraform plan

# Aplicar
terraform apply

# Ver los outputs con las credenciales
terraform output access_key_id
terraform output secret_access_key

# ⚠️ GUARDAR ESTOS VALORES — los necesitas para GitHub Secrets
```

---

## 🔧 PASO 4 — Módulos Terraform (1h 30min)

### terraform/modules/vpc/main.tf
```hcl
# Módulo VPC — reutilizable para DEV y PROD
# La diferencia entre ambientes está en las variables

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Necesario para que EC2 tenga hostname DNS
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Subnet pública — donde vive el EC2
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true # El EC2 recibe IP pública automáticamente

  tags = {
    Name        = "${var.project_name}-subnet-public-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Internet Gateway — permite tráfico de/hacia internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Route Table — enruta el tráfico de la subnet hacia internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-rt-public-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Asociar la subnet pública con la route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

### terraform/modules/vpc/variables.tf
```hcl
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente: dev o prod"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "El ambiente debe ser 'dev' o 'prod'."
  }
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block para la subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone para la subnet"
  type        = string
  default     = "us-east-1a"
}
```

### terraform/modules/vpc/outputs.tf
```hcl
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID de la subnet pública"
  value       = aws_subnet.public.id
}
```

---

### terraform/modules/security_group/main.tf
```hcl
# Security Group — firewall de la instancia EC2
# Principio de Zero Trust: deny all by default, allow only what's needed

resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg-web-${var.environment}"
  description = "Security group para el servidor web Nginx"
  vpc_id      = var.vpc_id

  # ─── INGRESS (tráfico entrante permitido) ─────────────────
  ingress {
    description = "HTTP desde internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ─── EGRESS (tráfico saliente) ────────────────────────────
  egress {
    description = "Todo el tráfico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ⚠️ NOTA: Puerto 22 (SSH) NO está abierto — Zero Trust
  # Para acceso a la instancia usar AWS Systems Manager Session Manager

  tags = {
    Name        = "${var.project_name}-sg-web-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### terraform/modules/security_group/variables.tf
```hcl
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "ID de la VPC donde crear el Security Group"
  type        = string
}
```

### terraform/modules/security_group/outputs.tf
```hcl
output "security_group_id" {
  description = "ID del Security Group creado"
  value       = aws_security_group.web.id
}
```

---

### terraform/modules/ec2/main.tf
```hcl
# Módulo EC2 — instancia t2.micro con Nginx
# Free tier: 750 horas/mes gratis

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role para que EC2 pueda acceder a SSM (acceso sin SSH)
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Adjuntar política SSM para acceso sin SSH (Zero Trust)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # User data — script que se ejecuta al iniciar la instancia
  # Instala Nginx y despliega la app de ejemplo
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment  = var.environment
    project_name = var.project_name
    app_content  = var.app_content
  }))

  # Protección contra terminación accidental en PROD
  disable_api_termination = var.environment == "prod" ? true : false

  tags = {
    Name        = "${var.project_name}-web-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### terraform/modules/ec2/user_data.sh
```bash
#!/bin/bash
# Script de inicialización de EC2
# Se ejecuta automáticamente al lanzar la instancia

set -e

# Actualizar paquetes
yum update -y

# Instalar Nginx
yum install -y nginx

# Crear el contenido de la app de ejemplo
cat > /usr/share/nginx/html/index.html << 'EOF'
${app_content}
EOF

# Iniciar y habilitar Nginx
systemctl start nginx
systemctl enable nginx

echo "✅ Nginx instalado y corriendo en ${environment}"
```

### terraform/modules/ec2/variables.tf
```hcl
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro" # Free tier
}

variable "subnet_id" {
  description = "ID de la subnet donde lanzar la instancia"
  type        = string
}

variable "security_group_id" {
  description = "ID del Security Group para la instancia"
  type        = string
}

variable "app_content" {
  description = "Contenido HTML de la app de ejemplo"
  type        = string
}
```

### terraform/modules/ec2/outputs.tf
```hcl
output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "DNS público de la instancia EC2"
  value       = aws_instance.web.public_dns
}
```

---

## 🔧 PASO 5 — Environments (20 min)

### terraform/environments/dev/backend.tf
```hcl
# Remote state para DEV
# El bucket y tabla se crearon en el bootstrap
terraform {
  backend "s3" {
    bucket         = "devops-demo-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-demo-state-lock"
    encrypt        = true
  }
}
```

### terraform/environments/dev/main.tf
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "Terraform"
      Pipeline    = "GitHub Actions"
    }
  }
}

# ─── VPC ──────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name      = var.project_name
  environment       = "dev"
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  availability_zone = var.availability_zone
}

# ─── SECURITY GROUP ───────────────────────────────────────────
module "security_group" {
  source = "../../modules/security_group"

  project_name = var.project_name
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id
}

# ─── EC2 ──────────────────────────────────────────────────────
module "ec2" {
  source = "../../modules/ec2"

  project_name      = var.project_name
  environment       = "dev"
  instance_type     = var.instance_type
  subnet_id         = module.vpc.subnet_id
  security_group_id = module.security_group.security_group_id
  app_content       = file("${path.root}/../../../app/index.html")
}
```

### terraform/environments/dev/variables.tf
```hcl
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
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
```

### terraform/environments/dev/outputs.tf
```hcl
output "web_url" {
  description = "URL de la app en DEV"
  value       = "http://${module.ec2.public_ip}"
}

output "instance_id" {
  value = module.ec2.instance_id
}
```

> ✅ Repite la misma estructura para `environments/prod/` cambiando:
> - `backend.tf`: bucket `devops-demo-terraform-state-prod`, key `prod/terraform.tfstate`
> - `variables.tf`: `vpc_cidr = "10.1.0.0/16"`, `subnet_cidr = "10.1.1.0/24"`

---

## 🔧 PASO 6 — App de ejemplo (10 min)

### app/index.html
```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DevOps Pipeline Demo</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0d1117;
      color: #e6edf3;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .container {
      text-align: center;
      padding: 2rem;
    }
    .badge {
      display: inline-block;
      padding: 0.4rem 1rem;
      border-radius: 20px;
      font-size: 0.85rem;
      font-weight: 600;
      margin-bottom: 1.5rem;
      letter-spacing: 0.05em;
      text-transform: uppercase;
    }
    .badge.dev  { background: #1a9e75; color: #fff; }
    .badge.prod { background: #ba7517; color: #fff; }
    h1 { font-size: 2.5rem; font-weight: 700; margin-bottom: 0.5rem; }
    p  { color: #8b949e; margin-bottom: 0.3rem; }
    .stack {
      margin-top: 2rem;
      display: flex;
      gap: 0.5rem;
      justify-content: center;
      flex-wrap: wrap;
    }
    .tag {
      background: #21262d;
      border: 1px solid #30363d;
      padding: 0.3rem 0.8rem;
      border-radius: 6px;
      font-size: 0.8rem;
      color: #8b949e;
    }
  </style>
</head>
<body>
  <div class="container">
    <span class="badge dev">DEV</span>
    <h1>DevOps Pipeline Demo</h1>
    <p>Desplegado con GitHub Actions + Terraform</p>
    <p>Infraestructura en AWS — EC2 t2.micro + Nginx</p>
    <div class="stack">
      <span class="tag">GitHub Actions</span>
      <span class="tag">Terraform</span>
      <span class="tag">AWS EC2</span>
      <span class="tag">Nginx</span>
      <span class="tag">Zero Trust</span>
    </div>
  </div>
</body>
</html>
```

---

## 🔧 PASO 7 — GitHub Actions Workflows (1h)

### .github/workflows/terraform-dev.yml
```yaml
name: "Terraform DEV Pipeline"

# Trigger: push a la rama develop
on:
  push:
    branches:
      - develop
    paths:
      - 'terraform/environments/dev/**'
      - 'terraform/modules/**'
      - 'app/**'

env:
  TF_VERSION: "1.7.0"
  AWS_REGION: "us-east-1"
  WORKING_DIR: "./terraform/environments/dev"

jobs:
  terraform-dev:
    name: "Deploy to DEV"
    runs-on: ubuntu-latest
    environment: dev  # GitHub Environment — para secrets específicos de DEV

    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}

    steps:
      # ─── 1. CHECKOUT ─────────────────────────────────────────
      - name: Checkout código
        uses: actions/checkout@v4

      # ─── 2. SETUP TERRAFORM ──────────────────────────────────
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      # ─── 3. CONFIGURAR CREDENCIALES AWS ──────────────────────
      # Access keys guardadas en GitHub Secrets
      # En producción real: usar OIDC en lugar de access keys
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      # ─── 4. TERRAFORM INIT ───────────────────────────────────
      - name: Terraform Init
        run: terraform init

      # ─── 5. TERRAFORM FORMAT CHECK ───────────────────────────
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        continue-on-error: false

      # ─── 6. TERRAFORM VALIDATE ───────────────────────────────
      - name: Terraform Validate
        run: terraform validate

      # ─── 7. SECURITY SCAN CON TFSEC ─────────────────────────
      - name: Security scan con tfsec
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          working_directory: ${{ env.WORKING_DIR }}
          soft_fail: true # No falla el pipeline en DEV, solo advierte

      # ─── 8. TERRAFORM PLAN ───────────────────────────────────
      - name: Terraform Plan
        id: plan
        run: terraform plan -out=tfplan -no-color
        continue-on-error: false

      # ─── 9. TERRAFORM APPLY (automático en DEV) ──────────────
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan

      # ─── 10. OBTENER OUTPUT Y NOTIFICAR ──────────────────────
      - name: Obtener URL de la app
        id: output
        run: echo "url=$(terraform output -raw web_url)" >> $GITHUB_OUTPUT

      - name: Notificación de deploy exitoso
        run: |
          echo "✅ Deploy a DEV exitoso"
          echo "🌐 URL: ${{ steps.output.outputs.url }}"
          echo "🕐 Timestamp: $(date)"
```

---

### .github/workflows/terraform-prod.yml
```yaml
name: "Terraform PROD Pipeline"

# Trigger: push a la rama main (requiere aprobación manual)
on:
  push:
    branches:
      - main
    paths:
      - 'terraform/environments/prod/**'
      - 'terraform/modules/**'
      - 'app/**'

env:
  TF_VERSION: "1.7.0"
  AWS_REGION: "us-east-1"
  WORKING_DIR: "./terraform/environments/prod"

jobs:
  # ─── JOB 1: VALIDACIÓN ────────────────────────────────────
  validate:
    name: "Validate & Plan PROD"
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}

    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Validate
        run: terraform validate

      # ─── Security scan ESTRICTO en PROD ──────────────────────
      - name: Security scan con tfsec (PROD — estricto)
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          working_directory: ${{ env.WORKING_DIR }}
          soft_fail: false # En PROD: falla el pipeline si hay problemas

      - name: Terraform Plan
        run: terraform plan -no-color

  # ─── JOB 2: DEPLOY CON APROBACIÓN MANUAL ──────────────────
  deploy-prod:
    name: "Deploy to PROD"
    runs-on: ubuntu-latest
    needs: validate          # Solo corre si validate pasó
    environment: prod        # ⚠️ Requiere aprobación manual en GitHub

    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}

    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply PROD
        run: terraform apply -auto-approve

      - name: Obtener URL de la app
        id: output
        run: echo "url=$(terraform output -raw web_url)" >> $GITHUB_OUTPUT

      - name: Notificación de deploy PROD exitoso
        run: |
          echo "🚀 Deploy a PROD exitoso"
          echo "🌐 URL: ${{ steps.output.outputs.url }}"
          echo "👤 Aprobado por: ${{ github.actor }}"
          echo "🕐 Timestamp: $(date)"
```

---

## 🔧 PASO 8 — Subir a GitHub y configurar (30 min)

### Crear el repo en GitHub:
```bash
# Desde tu repo local
git add .
git commit -m "feat: initial devops pipeline demo setup"

# Crear repo en GitHub (sin README)
# Luego:
git remote add origin https://github.com/TU_USUARIO/devops-pipeline-demo.git
git push -u origin develop
```

### Configurar GitHub Secrets:
```
Ir a: GitHub repo → Settings → Secrets and variables → Actions

Crear estos secrets:
  AWS_ACCESS_KEY_ID     → valor del bootstrap output
  AWS_SECRET_ACCESS_KEY → valor del bootstrap output
```

### Configurar GitHub Environments:
```
Ir a: GitHub repo → Settings → Environments

1. Crear environment "dev"
   - Sin restricciones (auto deploy)

2. Crear environment "prod"
   - Activar "Required reviewers"
   - Agregar tu usuario como reviewer
   - Esto activa la aprobación manual antes del deploy
```

---

## 🔧 PASO 9 — Pruebas (45 min)

### Test DEV (automático):
```bash
# Hacer un cambio y push a develop
git checkout develop
echo "<!-- test deploy $(date) -->" >> app/index.html
git add .
git commit -m "test: verificar pipeline DEV"
git push origin develop

# Verificar en GitHub Actions → debe correr automáticamente
# Al terminar: curl http://[IP_EC2_DEV] debe mostrar la app
```

### Test PROD (con aprobación):
```bash
# Merge develop → main
git checkout main
git merge develop
git push origin main

# Verificar en GitHub Actions:
# 1. Job "validate" corre automáticamente
# 2. Job "deploy-prod" queda en WAITING
# 3. Vas a GitHub → Actions → Review pending deployments
# 4. Apruebas el deploy
# 5. El apply se ejecuta en PROD
```

### Verificación final:
```bash
# DEV
curl http://[IP_EC2_DEV]
# Debe mostrar el HTML con badge "DEV"

# PROD
curl http://[IP_EC2_PROD]
# Debe mostrar el HTML con badge "PROD"

# State en S3
aws s3 ls s3://devops-demo-terraform-state-dev/
aws s3 ls s3://devops-demo-terraform-state-prod/
```

---

## 🎬 PASO 10 — Estructura del video (1h)

```
⏱ 00:00 - 02:00 | INTRODUCCIÓN
  → Qué vas a mostrar y por qué las decisiones técnicas importan

⏱ 02:00 - 05:00 | DIAGRAMA DE ARQUITECTURA
  → Mostrar el diagrama en diagrams.net
  → Explicar el flujo: GitHub → Actions → AWS → DEV/PROD
  → Mencionar Zero Trust, least privilege, remote state

⏱ 05:00 - 10:00 | CÓDIGO TERRAFORM
  → Mostrar estructura de módulos
  → Explicar bootstrap (S3 + DynamoDB + IAM)
  → Mostrar un módulo (vpc o ec2) y explicar variables

⏱ 10:00 - 13:00 | PIPELINE GITHUB ACTIONS
  → Mostrar terraform-dev.yml paso a paso
  → Mostrar terraform-prod.yml y explicar la aprobación manual
  → Mencionar: "En producción real usaría OIDC en vez de access keys"

⏱ 13:00 - 16:00 | DEMO EN VIVO — DEV
  → Push a develop → mostrar GitHub Actions corriendo
  → Mostrar los pasos: fmt → validate → tfsec → plan → apply
  → Abrir la URL del EC2 en el browser

⏱ 16:00 - 19:00 | DEMO EN VIVO — PROD
  → Merge a main → mostrar que el pipeline espera aprobación
  → Aprobar el deploy → mostrar apply corriendo
  → Abrir la URL del EC2 PROD

⏱ 19:00 - 22:00 | DECISIONES TÉCNICAS
  → EC2 vs ECS vs EKS: "Elegí EC2 por free tier y simplicidad"
  → Escalabilidad: "En producción agregaría ASG + ALB"
  → Security: IAM least privilege, SG sin :22, SSM en vez de SSH
  → Mejoras futuras: OIDC, WAF, CloudWatch alarms

⏱ 22:00 - 23:00 | CIERRE
  → Resumen de lo demostrado
```

---

## 🔧 PASO 11 — Destruir recursos (10 min)

```bash
# ⚠️ Hacer DESPUÉS de grabar el video

# Destruir PROD primero
cd terraform/environments/prod
terraform destroy -auto-approve

# Destruir DEV
cd ../dev
terraform destroy -auto-approve

# Destruir bootstrap (al final)
cd ../../bootstrap
terraform destroy -auto-approve

# Verificar que no quedaron recursos en AWS
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
```

---

## 📝 GitHub Secrets necesarios

| Secret | Valor | Dónde obtenerlo |
|--------|-------|-----------------|
| `AWS_ACCESS_KEY_ID` | Key ID del IAM user | `terraform output access_key_id` en bootstrap |
| `AWS_SECRET_ACCESS_KEY` | Secret del IAM user | `terraform output secret_access_key` en bootstrap |

---

## 🎯 Lo que demuestras con esto

```
✅ Pipeline profesional con 7 etapas de validación
✅ Separación real de ambientes DEV y PROD
✅ Remote state en S3 con versionado y encryption
✅ State locking con DynamoDB — evita conflictos
✅ Módulos reutilizables — DRY principle
✅ Aprobación manual antes de PROD
✅ IAM con least privilege — Zero Trust
✅ Puerto 22 cerrado — SSM en lugar de SSH
✅ tfsec para security scanning en el pipeline
✅ Decisión consciente de EC2 por free tier
✅ Todo en código — nada manual
✅ Mencionas OIDC como mejora para producción real
```

---

## 📋 Notas importantes sobre la actualización del plan

### ✅ Cambios implementados:
- **Estructura profesional**: Separación por responsabilidad (s3.tf, dynamodb.tf, iam.tf)
- **Configuración centralizada**: `terraform.tf` y `providers.tf` en la raíz
- **Documentación completa**: README.md global + específicos por módulo
- **Comentarios extensos**: Cada archivo explica decisiones técnicas
- **Best practices**: Validaciones, tags globales, least privilege

### 📁 Archivos actuales vs Plan original:
El plan original mostraba código en `main.tf` monolítico. Ahora está separado en archivos profesionales:
- `terraform/bootstrap/s3.tf` - Buckets S3 con encriptación y versionado
- `terraform/bootstrap/dynamodb.tf` - State locking con TTL
- `terraform/bootstrap/iam.tf` - IAM con least privilege detallado
- `terraform.tf` - Constraints globales
- `providers.tf` - Configuración global del provider

### 🚀 Próximos pasos:
1. Ejecutar bootstrap: `cd terraform/bootstrap && terraform init && terraform apply`
2. Guardar outputs para GitHub Secrets
3. Continuar con módulos (VPC, EC2, Security Group)
4. Configurar environments y workflows

¿Listo para ejecutar el bootstrap?
