terraform {
  backend "s3" {
    bucket         = "devops-demo-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-demo-state-lock"
    encrypt        = true
  }
}
