resource "aws_security_group" "bastion" {
  name        = "${local.prefix}-bastion"
  description = "Control bastion inbound and outbound access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      module.vpc.private_subnets[0].cidr_block,
      module.vpc.private_subnets[0].cidr_block,
    ]
  }

  tags = local.tags
}

resource "aws_security_group" "lb" {
  name        = "${local.prefix}-lb"
  description = "Allow access to Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "ecs_service" {
  name        = "${local.prefix}-ecs-service"
  description = "Access for the ECS Service"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      module.vpc.private_subnets_cidr_blocks[0],
      module.vpc.private_subnets_cidr_blocks[1],
    ]
  }

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lb.id,
    ]
  }

  tags = local.tags
}

resource "aws_security_group" "rds" {
  name        = "${local.prefix}-rds"
  description = "Allow access to the RDS database instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol  = "tcp"
    from_port = 3306
    to_port   = 3306

    security_groups = [
      aws_security_group.bastion.id,
      aws_security_group.ecs_service.id,
    ]
  }

  tags = local.tags
}

resource "aws_security_group" "efs" {
  name        = "${local.prefix}-efs"
  description = "Allow access to the NFS file system"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    security_groups = [
      aws_security_group.ecs_service.id,
    ]
  }

  tags = "Optional"
}
