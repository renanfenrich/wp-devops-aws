module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 4.1"

  identifier = "${var.prefix}-db"

  engine            = "mariadb"
  engine_version    = "10.6.7"
  instance_class    = "db.t2.micro"
  allocated_storage = 5
  port              = "3306"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring
  monitoring_interval    = "30"
  monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = true

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = module.vpc.outputs.private_subnets

  # DB parameter group
  family = "mariadb10.6"

  # DB option group
  major_engine_version = "10.6"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.tags
}
