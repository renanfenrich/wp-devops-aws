output "vpc_id" {
  value = module.vpc.id
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "db_endpoint" {
  value = module.rds.db_instance_endpoint
}
