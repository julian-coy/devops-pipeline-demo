# DevOps Pipeline Demo

> Pipeline profesional de CI/CD con GitHub Actions + Terraform + AWS.
> Incluye validación de IaC, security scanning, separación real de ambientes y Zero Trust.

## Flujo general

```
Developer
    │
    ├── push a develop
    │       └── GitHub Actions (DEV pipeline)
    │               ├── fmt + validate + tfsec (soft_fail) + plan
    │               └── apply automático → EC2 DEV
    │
    └── Pull Request a main
            └── GitHub Actions (PROD pipeline)
                    ├── validate job → corre en el PR (muestra el plan)
                    └── deploy-prod job → workflow_dispatch manual → EC2 PROD
```

## Arquitectura

El diagrama completo está en [`architecture.drawio`](architecture.drawio) — importar en [app.diagrams.net](https://app.diagrams.net).

### Dos capas de infraestructura

**Bootstrap** (ejecutado una vez desde local con credenciales de administrador):
- S3 bucket DEV — remote state con versioning y AES256
- S3 bucket PROD — remote state con versioning y AES256, separado del de DEV
- DynamoDB — state locking para prevenir ejecuciones concurrentes
- IAM User `github-actions` — least privilege: solo S3, DynamoDB y EC2

**Environments** (creados por el pipeline):
- VPC + Subnet pública + Internet Gateway + Route Table
- Security Group — HTTP:80 y HTTPS:443 abiertos, **puerto 22 cerrado**
- EC2 t2.micro — Amazon Linux 2023 + Nginx + app HTML
- IAM Role con SSM — acceso a la instancia sin SSH (Zero Trust)

DEV usa CIDRs `10.0.x.x`, PROD usa `10.1.x.x`.

## Estructura del proyecto

```
devops-pipeline-demo/
├── architecture.drawio              # Diagrama de arquitectura
├── app/
│   └── index.html                   # App (badge DEV/PROD dinámico via templatefile)
├── terraform/
│   ├── bootstrap/                   # Infra base: S3, DynamoDB, IAM
│   │   ├── main.tf
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── modules/                     # Módulos reutilizables
│   │   ├── vpc/
│   │   ├── ec2/
│   │   └── security_group/
│   └── environments/
│       ├── dev/                     # main.tf + backend.tf + variables.tf + outputs.tf
│       └── prod/
└── .github/
    └── workflows/
        ├── terraform-dev.yml        # Pipeline DEV (auto en push a develop)
        └── terraform-prod.yml       # Pipeline PROD (validate en PR + deploy manual)
```

## Setup desde cero

### Prerrequisitos
- AWS Account con credenciales de administrador (`aws configure`)
- Terraform >= 1.0
- GitHub repository con las dos ramas: `develop` y `main`
- Branch protection en `main` (sin push directo — todo por PR)

### Paso 1: Bootstrap

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

Guarda los outputs: `access_key_id` y `secret_access_key`.

### Paso 2: GitHub Secrets

**Settings → Secrets and variables → Actions**

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Output `access_key_id` del bootstrap |
| `AWS_SECRET_ACCESS_KEY` | Output `secret_access_key` del bootstrap |

### Paso 3: Activar pipelines

```bash
# Cualquier push a develop activa el pipeline DEV
git checkout develop
git push origin develop

# Para PROD: abrir PR de develop a main
# El job "validate" corre automáticamente en el PR
# Al mergear el PR, lanzar el deploy manualmente:
# Actions → Terraform PROD Pipeline → Run workflow → Branch: main
```

## Pipeline DEV — 7 etapas

| # | Paso | Descripción |
|---|------|-------------|
| a | `terraform init` | Inicializa, descarga providers |
| b | `terraform fmt --check` | Falla si el código no está formateado |
| c | `terraform validate` | Valida sintaxis sin tocar AWS |
| d | `tfsec` (soft_fail) | Security scan — advierte pero no bloquea |
| e | `terraform plan` | Genera el plan y lo guarda como artefacto |
| f | `terraform apply` | Aplica el artefacto del paso anterior (auto) |
| g | Notificación | Publica URL de la app en el Summary |

## Pipeline PROD — 2 jobs

**Job 1: validate** — se dispara al abrir el PR desde `develop`
- `fmt + validate + tfsec (strict) + plan`
- tfsec es estricto: si hay issues de seguridad, bloquea el merge
- El plan queda visible en los checks del PR

**Job 2: deploy-prod** — solo corre manualmente via `workflow_dispatch`
- Descarga el artefacto del plan y ejecuta `terraform apply`
- Nadie puede deployar a PROD sin intención explícita

## Decisiones técnicas

### EC2 vs ECS vs EKS
- **EC2** — elegido para el demo: free tier, foco en el pipeline, no en el runtime
- **ECS** — para apps containerizadas sin querer gestionar K8s
- **EKS** — para portabilidad entre clouds o equipos con expertise en K8s

### Credenciales
- Demo: access keys del IAM user en GitHub Secrets
- Producción: **OIDC** — GitHub Actions asume un IAM Role sin access keys estáticas

### tfsec en DEV vs PROD
- **DEV**: `soft_fail = true` — reporta issues, no bloquea. Útil para desarrollo iterativo.
- **PROD**: sin soft_fail — cualquier issue de seguridad bloquea el deploy.

### Remote state separado
- S3 bucket DEV y S3 bucket PROD son recursos distintos.
- Un problema en el state de DEV no puede afectar el de PROD.

### IMDSv2 y EBS encriptado
- `http_tokens = "required"` en el EC2 — previene ataques SSRF al metadata service.
- `root_block_device { encrypted = true }` — datos en reposo protegidos.

## Seguridad implementada

| Control | Estado |
|---------|--------|
| Remote state encriptado (AES256) | Activo |
| State locking (DynamoDB) | Activo |
| IAM least privilege | Activo |
| Sin credenciales en código | Activo |
| tfsec en pipeline | Activo |
| IMDSv2 requerido | Activo |
| EBS encriptado | Activo |
| Puerto 22 cerrado | Activo |
| Acceso via SSM (no SSH) | Activo |
| Branch protection en main | Activo |

## Mejoras para producción

- OIDC en lugar de access keys estáticas
- EC2 en subnet privada + ALB en subnet pública
- NAT Gateway para egress controlado
- WAF frente al ALB
- VPC Flow Logs habilitados
- CloudWatch + SNS para alertas
- Cuentas AWS separadas por ambiente (AWS Organizations)

## Limpieza

```bash
cd terraform/environments/prod && terraform init && terraform destroy -auto-approve
cd ../dev                       && terraform init && terraform destroy -auto-approve
cd ../../bootstrap               && terraform destroy -auto-approve
```
