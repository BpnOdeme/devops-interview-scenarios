# Step 4: Fix Dependencies

## Task

Resolve circular dependencies and other dependency issues in the configuration.

## Instructions

### 1. Fix Circular Dependency Between Security Groups

The security groups reference each other, creating a circular dependency. Fix this:

```bash
nano /root/infrastructure/main.tf
```

#### Option A: Use CIDR blocks instead of security group references

```hcl
resource "aws_security_group" "web_sg" {
  name = "web_sg"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Use CIDR instead of SG reference
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name = "app_sg"
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Use CIDR instead of SG reference
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

#### Option B: Use separate ingress rules

```hcl
resource "aws_security_group" "web_sg" {
  name = "web_sg"
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name = "app_sg"
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add rules after SGs are created
resource "aws_security_group_rule" "web_from_app" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
  security_group_id        = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_sg.id
  security_group_id        = aws_security_group.app_sg.id
}
```

### 2. Add Required Provider Configuration

Ensure providers are properly configured:

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
```

### 3. Fix Resource Dependencies

Ensure resources depend on each other correctly:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]  # Add dependency
  
  tags = {
    Name = "WebServer"
  }
  
  depends_on = [aws_security_group.web_sg]  # Explicit dependency
}
```

### 4. Validate Dependency Graph

Check the dependency graph:
```bash
# Generate dependency graph (requires graphviz)
terraform graph | grep -E "aws_security_group|aws_instance"

# Or just validate there are no cycles
terraform validate
```

### 5. Complete Working Configuration

Your main.tf should now have:
- No duplicate resources
- No circular dependencies
- All variables defined
- Proper provider configuration
- Valid resource references

## Validation

Test the configuration:
```bash
# Format the code
terraform fmt

# Validate configuration
terraform validate

# Initialize if needed
terraform init

# Plan to see what would be created
terraform plan
```

## Checklist

- [ ] Removed circular dependency between security groups
- [ ] Added proper provider requirements
- [ ] Fixed resource dependencies
- [ ] Configuration validates without errors
- [ ] Terraform plan executes (may show AWS credential errors, that's OK)