data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${var.prefix}-bastion"

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  availability_zone      = local.availability_zone
  subnet_id              = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.bastion_key_name

  user_data = file("./templates/bastion/user-data.sh")

  tags = local.tags
}
