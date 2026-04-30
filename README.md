# 🚀 DevOps Pipeline Demo

> **Objetivo:** Demostrar seniority técnico con un pipeline profesional de CI/CD usando GitHub Actions + Terraform + AWS

## 📋 Lo que construimos

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

## 🏗️ Arquitectura

### Infraestructura como Código (IaC)
- **Terraform**: Módulos reutilizables para VPC, EC2, Security Groups
- **Remote State**: S3 buckets separados para DEV/PROD
- **State Locking**: DynamoDB para prevenir conflictos concurrentes
- **Least Privilege**: IAM user específico para CI/CD

### Pipeline CI/CD
- **GitHub Actions**: Workflows separados para DEV y PROD
- **DEV**: Push a `develop` → deploy automático
- **PROD**: Push a `main` → aprobación manual requerida
- **Security**: tfsec para análisis de seguridad en el pipeline

### Zero Trust Security
- **No SSH**: Acceso a EC2 via AWS Systems Manager Session Manager
- **No puerto 22**: Security Groups sin SSH abierto
- **Secrets**: SSM Parameter Store para configuración sensible
- **IAM**: Principio de least privilege en todos los recursos

## 📁 Estructura del Proyecto

```
devops-pipeline-demo/
├── terraform.tf                    # Constraints de versiones globales
├── providers.tf                    # Configuración global del provider AWS
├── README.md                       # Esta documentación
├── app/
│   └── index.html                  # App de ejemplo (Nginx)
├── terraform/
│   ├── bootstrap/                  # Infra base (S3, DynamoDB, IAM)
│   │   ├── main.tf                 # Recursos del bootstrap
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md               # Docs específicas del bootstrap
│   ├── modules/                    # Módulos reutilizables
│   │   ├── vpc/                    # VPC + Subnet + IGW + Route Table
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ec2/                    # EC2 t2.micro + IAM role + user data
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── security_group/         # Security Group (HTTP/HTTPS only)
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/               # Config por ambiente
│       ├── dev/                    # Ambiente DEV
│       │   ├── main.tf             # Llama módulos con config DEV
│       │   ├── variables.tf
│       │   ├── terraform.tfvars    # Valores específicos DEV
│       │   ├── backend.tf          # Remote state DEV
│       │   └── outputs.tf
│       └── prod/                   # Ambiente PROD
│           ├── main.tf             # Llama módulos con config PROD
│           ├── variables.tf
│           ├── terraform.tfvars    # Valores específicos PROD
│           ├── backend.tf          # Remote state PROD
│           └── outputs.tf
└── .github/
    └── workflows/
        ├── terraform-dev.yml       # Pipeline DEV (auto)
        └── terraform-prod.yml      # Pipeline PROD (manual approval)
```

## 🚀 Inicio Rápido

### Prerrequisitos
- AWS Account con credenciales configuradas (`aws configure`)
- Terraform >= 1.0
- GitHub repository creado

### Paso 1: Bootstrap (Infra Base)
```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

**Guarda los outputs** (access keys y nombres de recursos) para el siguiente paso.

### Paso 2: Configurar GitHub Secrets
Ve a GitHub → Settings → Secrets and variables → Actions

Crea estos secrets:
- `AWS_ACCESS_KEY_ID`: Valor del output `access_key_id`
- `AWS_SECRET_ACCESS_KEY`: Valor del output `secret_access_key`

### Paso 3: Configurar Environments
Ve a GitHub → Settings → Environments

Crea:
- **dev**: Sin restricciones (deploy automático)
- **prod**: Con required reviewers (tu usuario) para aprobación manual

### Paso 4: Crear Módulos
Los módulos ya están creados. Solo ejecuta:
```bash
# DEV
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# PROD
cd ../prod
terraform init
terraform plan
terraform apply
```

### Paso 5: Push y Deploy
```bash
git add .
git commit -m "feat: initial devops pipeline setup"
git push origin develop  # Trigger DEV pipeline
git merge develop
git push origin main     # Trigger PROD pipeline (requiere aprobación)
```

## 🎯 Decisiones Técnicas

### Por qué Terraform?
- **Declarativo**: Describe el estado deseado, no los pasos
- **Idempotente**: Ejecutar múltiples veces = mismo resultado
- **Módulos**: Reutilización de código
- **Plan**: Preview de cambios antes de aplicar

### Por qué GitHub Actions?
- **Integración nativa**: Con GitHub (repos, secrets, environments)
- **Free tier**: 2000 minutos/mes gratis
- **OIDC ready**: Para producción sin access keys estáticas
- **Matrices**: Paralelización de jobs

### Por qué AWS?
- **Free tier**: t2.micro gratis por 750 horas/mes
- **Servicios maduros**: S3, DynamoDB, EC2, IAM
- **Global**: Regiones en todo el mundo
- **Documentación**: Excelente soporte

### Por qué Zero Trust?
- **Principio de seguridad**: "Never trust, always verify"
- **No SSH**: Evita gestión de keys, usa Session Manager
- **Least privilege**: Solo permisos necesarios
- **Defense in depth**: Múltiples capas de seguridad

## 📊 Costos Estimados (Free Tier)

| Servicio | Costo Mensual | Notas |
|----------|---------------|-------|
| EC2 t2.micro | $0 | 750 horas gratis |
| S3 | ~$1 | 5GB storage + requests |
| DynamoDB | $0 | Pay-per-request |
| Data Transfer | $0 | 100GB gratis |
| **TOTAL** | **~$1/mes** | Solo si excedes free tier |

## 🔒 Seguridad

### En Desarrollo
- ✅ Remote state encriptado
- ✅ State locking
- ✅ IAM least privilege
- ✅ No credenciales en código
- ✅ tfsec en pipeline

### Para Producción
- 🔄 Migrar a OIDC (no access keys)
- 🔄 WAF + CloudWatch alarms
- 🔄 Multi-AZ deployment
- 🔄 Backup strategies
- 🔄 Cost monitoring

## 🧪 Testing

### Test DEV (Automático)
```bash
git checkout develop
echo "<!-- test $(date) -->" >> app/index.html
git add . && git commit -m "test: pipeline DEV"
git push origin develop
```
Verifica: GitHub Actions corre automáticamente → EC2 se actualiza

### Test PROD (Manual Approval)
```bash
git checkout main
git merge develop
git push origin main
```
Verifica: Job "validate" corre → Espera aprobación → Deploy a PROD

## 🧹 Limpieza

Después de la demo, destruye todo para evitar costos:

```bash
# PROD primero
cd terraform/environments/prod
terraform destroy

# DEV
cd ../dev
terraform destroy

# Bootstrap al final
cd ../../bootstrap
terraform destroy
```

## 📚 Recursos

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Zero Trust Architecture](https://www.cloudflare.com/learning/security/glossary/what-is-zero-trust/)

## 🤝 Contribuir

1. Fork el repo
2. Crea una branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'feat: nueva funcionalidad'`)
4. Push (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es para fines educativos. No usar en producción sin modificaciones de seguridad.

---

**¿Preguntas?** Revisa los README.md específicos en cada directorio para más detalles.
