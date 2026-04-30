# =============================================================================
# IAM USER FOR GITHUB ACTIONS CI/CD PIPELINE
# =============================================================================
# Usuario con least privilege: solo permisos necesarios para CI/CD.
# En producción real: usar OIDC (OpenID Connect) en lugar de access keys.
# OIDC es más seguro: sin necesidad de secrets estáticos, integración nativa GitHub.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# IAM USER
# ─────────────────────────────────────────────────────────────────────────────
# Usuario específico para CI/CD (no es usuario humano)
# Aislado: si se compromete la key, solo afecta al pipeline, no al acceso administrativo

resource "aws_iam_user" "github_actions" {
  name = "${var.project_name}-github-actions"

  tags = {
    Name = "GitHub Actions Deploy User"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# ACCESS KEYS (CREDENCIALES PARA CI/CD)
# ─────────────────────────────────────────────────────────────────────────────
# AccessKeyId + SecretAccessKey para autenticación
# ⚠️ SEGURIDAD: Estas keys deben guardarse en GitHub Secrets, NUNCA en código

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name

  lifecycle {
    create_before_destroy = true  # Previene interrupciones si se rota la key
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM POLICY - LEAST PRIVILEGE
# ─────────────────────────────────────────────────────────────────────────────
# Política inline: permisos mínimos necesarios para que CI/CD funcione
# Dividida en 3 statements por responsabilidad (S3, DynamoDB, EC2/IAM)

resource "aws_iam_user_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      # ───────────────────────────────────────────────────────────────────────
      # STATEMENT 1: S3 PERMISSIONS FOR TERRAFORM STATE
      # ───────────────────────────────────────────────────────────────────────
      # Permite leer/escribir archivos .tfstate en buckets DEV y PROD
      # Necesario para 'terraform init', 'plan', 'apply'
      {
        Sid    = "TerraformStateBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",      # Leer el state
          "s3:PutObject",      # Escribir nuevos states
          "s3:DeleteObject",   # Limpieza (raro, pero necesario)
          "s3:ListBucket"      # Listar objetos en el bucket
        ]
        Resource = [
          aws_s3_bucket.state_dev.arn,
          "${aws_s3_bucket.state_dev.arn}/*",
          aws_s3_bucket.state_prod.arn,
          "${aws_s3_bucket.state_prod.arn}/*"
        ]
      },

      # ───────────────────────────────────────────────────────────────────────
      # STATEMENT 2: DYNAMODB PERMISSIONS FOR STATE LOCKING
      # ───────────────────────────────────────────────────────────────────────
      # Permite crear/liberar locks en DynamoDB
      # Sin esto: terraform plan/apply fallaría con error de locking
      {
        Sid    = "DynamoDBStateLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",    # Leer lock existente
          "dynamodb:PutItem",    # Crear nuevo lock
          "dynamodb:DeleteItem"  # Liberar lock
        ]
        Resource = aws_dynamodb_table.state_lock.arn
      },

      # ───────────────────────────────────────────────────────────────────────
      # STATEMENT 3: EC2 & INFRASTRUCTURE MANAGEMENT
      # ───────────────────────────────────────────────────────────────────────
      # ⚠️ NOTA: ec2:* es amplio para esta demo
      # En PRODUCCIÓN: restringir a acciones específicas y recursos con ARNs
      # Ejemplo: "ec2:RunInstances", "ec2:TerminateInstances" (no todo ec2:*)
      {
        Sid    = "InfrastructureManagement"
        Effect = "Allow"
        Action = [
          # VPC & Networking
          "ec2:*",
          # Parameter Store (para secrets/config)
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          # IAM Roles para EC2
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetRole",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          # Instance profiles para EC2
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile"
        ]
        Resource = "*"  # Todo, pero en prod limitar a resource ARNs específicos
      }
    ]
  })
}
