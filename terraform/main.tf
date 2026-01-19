provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  project_name       = var.project_name
  tags               = local.common_tags
}

module "compute" {
  source = "./modules/compute"

  vpc_id         = module.networking.vpc_id
  subnet_id      = module.networking.public_subnet_id
  instance_type  = var.instance_type
  instance_count = var.instance_count
  user_data      = file("${path.module}/user_data.sh")
  project_name   = var.project_name
  tags           = local.common_tags
}
