variable "project" {
  type        = string
  description = "Project name"
}

variable "prefix" {
  type        = string
  description = "Short name for the project"
}

variable "region" {
  type        = string
  description = "Default AWS region to deploy"
  default     = "us-east-1"
}

variable "db_name" {
  description = "Database name for the RDS instance"
}

variable "db_username" {
  description = "Root username for the RDS instance"
}

variable "db_password" {
  description = "Root uassword for the RDS instance"
}
