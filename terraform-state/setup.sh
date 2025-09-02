#!/bin/bash

set -e

echo "Setting up broken Terraform environment..."

# Install Terraform
echo "Installing Terraform..."
wget -q https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip -qq terraform_1.5.0_linux_amd64.zip
mv terraform /usr/local/bin/
rm terraform_1.5.0_linux_amd64.zip

# Create project directory
mkdir -p /root/infrastructure
cd /root/infrastructure

# Create BROKEN main.tf with multiple issues
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    # ISSUE: Access key and secret missing
    # ISSUE: DynamoDB lock table not configured
    # encrypt = true
    # dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.region  # ISSUE: Variable not defined
}

# ISSUE: Duplicate resource name
resource "aws_instance" "web" {
  ami           = "ami-12345678"  # ISSUE: Invalid AMI ID
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}

resource "aws_instance" "web" {  # ISSUE: Duplicate resource name
  ami           = "ami-87654321"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer2"
  }
}

# ISSUE: Circular dependency
resource "aws_security_group" "web_sg" {
  name = "web_sg"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.app_sg.id]  # References app_sg
  }
}

resource "aws_security_group" "app_sg" {
  name = "app_sg"
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.web_sg.id]  # References web_sg - CIRCULAR!
  }
}

# ISSUE: Module source doesn't exist
module "vpc" {
  source = "./modules/vpc"  # Directory doesn't exist
  
  cidr_block = "10.0.0.0/16"
}

# ISSUE: Invalid resource reference
output "instance_ip" {
  value = aws_instance.webapp.public_ip  # Resource 'webapp' doesn't exist
}

# ISSUE: Invalid resource configuration
resource "aws_s3_bucket" "data" {
  bucket = "my-tf-test-bucket-${random_id.bucket_suffix.hex}"  # random_id not defined
  acl    = "private"  # Deprecated argument in newer AWS provider
  
  versioning {  # Deprecated block syntax
    enabled = true
  }
}
EOF

# Create CORRUPTED terraform.tfstate
cat > terraform.tfstate <<'EOF'
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 42,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-99999999",
            "instance_type": "t2.micro"
            "tags": {
              "Name": "OldWebServer"
            },
            "public_ip": "54.123.456.789"
          },
          "private": "corrupted_data"
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_security_group",
      "name": "orphaned_sg",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "sg-0123456789abcdef0",
            "name": "orphaned_security_group",
            "description": "This SG no longer exists in config"
          }
        }
      ]
    }
  ]
}
EOF

# Create incomplete lock file
cat > .terraform.lock.hcl <<'EOF'
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version = "5.0.0"
  # ISSUE: Hashes incomplete/corrupted
  hashes = [
    "h1:corrupted_hash_value",
  ]
}
EOF

# Create a backup of the corrupted state
cp terraform.tfstate terraform.tfstate.backup

# Create variables.tf with missing definitions
cat > variables.tf <<'EOF'
# ISSUE: region variable is used but not defined here

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# ISSUE: Missing required variables for the configuration
EOF

# Create a state lock file to simulate stuck lock
mkdir -p .terraform
cat > .terraform/terraform.tfstate.lock.info <<'EOF'
{
  "ID": "1234567890-abcd-efgh-ijkl-mnopqrstuvwx",
  "Path": "terraform.tfstate",
  "Operation": "OperationTypeApply",
  "Who": "user@hostname",
  "Version": "1.5.0",
  "Created": "2024-01-01T00:00:00Z"
}
EOF

# Create reference Terraform configuration
mkdir -p /tmp/reference
cat > /tmp/reference/terraform-reference.tf <<'EOF'
# Reference Terraform Configuration - Best Practices

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Proper resource definition
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name = "${var.environment}-web-server"
  }
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security group without circular dependency
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web servers"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Proper S3 bucket configuration (newer syntax)
resource "aws_s3_bucket" "data" {
  bucket = "${var.environment}-data-bucket-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "private"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Proper output
output "instance_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP of the web server"
}
EOF

echo ""
echo "Broken Terraform environment created!"
echo ""
echo "Issues to fix:"
echo "1. Corrupted state file (JSON syntax errors)"
echo "2. Duplicate resource definitions"
echo "3. Circular dependencies between security groups"
echo "4. Missing variable definitions"
echo "5. Invalid module sources"
echo "6. Incorrect resource references"
echo "7. State lock is stuck"
echo "8. Orphaned resources in state"
echo ""
echo "Start by checking: terraform validate"