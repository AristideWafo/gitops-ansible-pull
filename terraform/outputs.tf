output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = module.networking.public_subnet_id
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = module.compute.instance_ids
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = module.compute.instance_public_ips
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = module.compute.instance_private_ips
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.compute.security_group_id
}
