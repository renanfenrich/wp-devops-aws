terraform {
  backend "s3" {
    encrypt        = true
    region         = "us-east-1"
    key            = "development.tfstate"
    bucket         = "apiki-devops-renanfenrich-tfstate-01"
    dynamodb_table = "apiki-devops-renanfenrich-tfstate-01-lock"
  }
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
  tags = {
    Environment = terraform.workspace
    Project     = var.project
    Terraform   = "true"
  }
}
