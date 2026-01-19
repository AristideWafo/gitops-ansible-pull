terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "ansible-pull-237"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
