# Terraform Infrastructure

This Terraform configuration deploys three EC2 instances running Ubuntu 22.04 in a public subnet on AWS.

## Architecture

- **VPC**: Custom VPC with CIDR block 10.0.0.0/16
- **Public Subnet**: Single public subnet with Internet Gateway
- **EC2 Instances**: Three Ubuntu 22.04 instances with Apache web server
- **Security Group**: Allows SSH (port 22) and HTTP (port 80) access

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- An S3 bucket for remote state storage

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your desired configuration

3. Update the S3 bucket name in `versions.tf` for the backend configuration

4. Initialize Terraform:
   ```bash
   terraform init
   ```

5. Review the planned changes:
   ```bash
   terraform plan
   ```

6. Apply the configuration:
   ```bash
   terraform apply
   ```

## Outputs

After successful deployment, Terraform will output:
- `instance_public_ips`: Public IP addresses of all EC2 instances
- `vpc_id`: ID of the created VPC
- `subnet_id`: ID of the public subnet

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Module Structure

- `modules/networking`: VPC, subnet, Internet Gateway, and routing configuration
- `modules/compute`: EC2 instances, security groups, and user data

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| aws_region | AWS region to deploy resources | string | us-east-1 |
| instance_type | EC2 instance type | string | t2.micro |
| instance_count | Number of EC2 instances to create | number | 3 |
| vpc_cidr | CIDR block for VPC | string | 10.0.0.0/16 |
| public_subnet_cidr | CIDR block for public subnet | string | 10.0.1.0/24 |
| project_name | Name of the project | string | gitops-ansible-pull |
| environment | Environment name | string | dev |
