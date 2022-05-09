resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"

  tags = local.tags
}

resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${local.prefix}-task-exec-role-policy"
  path        = "/"
  description = "Allow retrieving of images and adding to logs"
  policy      = file("./templates/ecs/task-exec-role.json")
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.prefix}-task-exec-role"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

resource "aws_iam_role" "app_iam_role" {
  name               = "${local.prefix}-app-task"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-app"

  tags = local.tags
}

resource "aws_ecr_repository" "aws_ecr_repository_fpm" {
  name                 = var.prefix
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

resource "aws_ecr_repository" "aws_ecr_repository_proxy" {
  name                 = var.prefix
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

data "template_file" "app_container_definitions" {
  template = file("./templates/ecs/container-definitions.json.tpl")

  vars = {
    region                 = var.region
    image_fpm              = aws_ecr_repository.aws_ecr_repository_fpm.repository_url
    image_proxy            = aws_ecr_repository.aws_ecr_repository_proxy.repository_url
    db_host                = module.rds.db_instance_endpoint
    db_name                = module.rds.db_instance_name
    db_user                = var.db_username
    db_pass                = var.db_password
    log_group_name         = aws_cloudwatch_log_group.ecs_task_logs.name
    s3_storage_bucket_name = aws_s3_bucket.app_public_files.bucket
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.prefix}-app"
  container_definitions    = data.template_file.app_container_definitions.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.app_iam_role.arn

  volume {
    name = "static"
  }

  tags = local.tags
}

resource "aws_ecs_service" "app" {
  name             = "${local.prefix}-app"
  cluster          = aws_ecs_cluster.main.name
  task_definition  = aws_ecs_task_definition.app.family
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
    ]
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "proxy"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.app_https]
}

data "template_file" "ecs_s3_write_policy" {
  template = file("./templates/ecs/s3-write-policy.json.tpl")

  vars = {
    bucket_arn = aws_s3_bucket.app_public_files.arn
  }
}

resource "aws_iam_policy" "ecs_s3_access" {
  name        = "${local.prefix}-AppS3AccessPolicy"
  path        = "/"
  description = "Allow access to the recipe app S3 bucket"

  policy = data.template_file.ecs_s3_write_policy.rendered
}

resource "aws_iam_role_policy_attachment" "ecs_s3_access" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}
