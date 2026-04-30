terraform {
  backend "s3" {
    bucket         = "devops-demo-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-demo-state-lock"
    encrypt        = true
  }
}
