# Step 1: Analyze State Issues

## Task

Understand the current state of the Terraform configuration and identify all issues.

## Instructions

1. **Navigate to the project directory**:
   ```bash
   cd /root/infrastructure
   ```

2. **Check Terraform version**:
   ```bash
   terraform version
   ```

3. **Try to validate the configuration** (REQUIRED for verification):
   ```bash
   terraform validate
   ```
   This will show configuration errors.

4. **Examine the main configuration**:
   ```bash
   cat main.tf
   ```

5. **Check the state file**:
   ```bash
   cat terraform.tfstate | head -20
   ```
   Look for JSON syntax errors.

6. **Check if there's a state lock**:
   ```bash
   ls -la .terraform/
   cat .terraform/terraform.tfstate.lock.info 2>/dev/null
   ```

7. **List files in the directory**:
   ```bash
   ls -la
   ```

8. **Check the reference configuration**:
   ```bash
   cat /tmp/reference/terraform-reference.tf
   ```

## Issues to Identify

### Configuration Issues
- [ ] Duplicate resource names (`aws_instance.web` defined twice)
- [ ] Undefined variables (`var.region` not defined)
- [ ] Invalid resource references (`aws_instance.webapp` doesn't exist)
- [ ] Module source doesn't exist (`./modules/vpc`)
- [ ] Circular dependencies (security groups reference each other)

### State Issues
- [ ] JSON syntax errors in state file (missing comma)
- [ ] Orphaned resources in state (resources not in config)
- [ ] State lock file exists (may be stuck)

### Backend Issues
- [ ] S3 backend missing credentials
- [ ] DynamoDB table for locking not configured

## Common Terraform Errors

### Duplicate Resource
```
Error: Duplicate resource "aws_instance" configuration
```

### Circular Dependency
```
Error: Cycle: aws_security_group.web_sg, aws_security_group.app_sg
```

### Invalid Reference
```
Error: Reference to undeclared resource
```

## Important Files

- `main.tf` - Main configuration (has errors)
- `terraform.tfstate` - State file (corrupted)
- `terraform.tfstate.backup` - Backup of state
- `.terraform.lock.hcl` - Provider lock file
- `.terraform/terraform.tfstate.lock.info` - Lock information

Once you understand all the issues, proceed to fix them in the next steps.