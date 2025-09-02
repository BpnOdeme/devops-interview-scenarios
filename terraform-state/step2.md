# Step 2: Fix Configuration Errors

## Task

Fix the configuration errors in main.tf to make it valid.

## Instructions

### 1. Fix Duplicate Resources

Edit main.tf and rename the duplicate `aws_instance.web`:
```bash
nano /root/infrastructure/main.tf
```

Change the second instance:
```hcl
# First instance keeps the name "web"
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}

# Second instance gets a new name
resource "aws_instance" "web2" {  # Changed from "web" to "web2"
  ami           = "ami-87654321"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer2"
  }
}
```

### 2. Define Missing Variables

Create or update variables.tf:
```bash
cat >> variables.tf <<'EOF'

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
EOF
```

### 3. Fix Invalid Output Reference

In main.tf, fix the output to reference an existing resource:
```hcl
output "instance_ip" {
  value = aws_instance.web.public_ip  # Changed from webapp to web
}
```

### 4. Fix or Remove Module Reference

Either remove the module or create a placeholder:

Option A - Remove the module:
```hcl
# Comment out or delete the module block
# module "vpc" {
#   source = "./modules/vpc"
#   cidr_block = "10.0.0.0/16"
# }
```

Option B - Create module directory:
```bash
mkdir -p modules/vpc
cat > modules/vpc/main.tf <<'EOF'
variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

# Placeholder VPC module
output "vpc_id" {
  value = "vpc-placeholder"
}
EOF
```

### 5. Fix S3 Bucket Configuration

Add the missing random_id resource:
```hcl
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

Or simplify the bucket name:
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-tf-test-bucket-unique-name"  # Use a fixed unique name
  
  # Remove deprecated acl and versioning blocks
}

# Use separate resources for ACL and versioning (newer syntax)
resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

### 6. Temporary Fix for Backend

For now, comment out the backend configuration or use local backend:
```hcl
terraform {
  required_version = ">= 1.0"
  
  # Temporarily use local backend
  # backend "s3" {
  #   bucket = "terraform-state-bucket"
  #   key    = "prod/terraform.tfstate"
  #   region = "us-east-1"
  # }
}
```

## Validation

After making changes, validate the configuration:
```bash
terraform fmt     # Format the code
terraform validate # Should show fewer errors
```

## Checklist

- [ ] Renamed duplicate `aws_instance.web` to `aws_instance.web2`
- [ ] Added missing `region` variable definition
- [ ] Fixed output reference from `webapp` to `web`
- [ ] Handled module issue (removed or created placeholder)
- [ ] Fixed S3 bucket configuration
- [ ] Temporarily disabled S3 backend

The circular dependency issue will be fixed in the next step.