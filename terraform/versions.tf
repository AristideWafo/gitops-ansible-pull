terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "ansible-pull-237" # FIXME: Replace with your S3 bucket name
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
