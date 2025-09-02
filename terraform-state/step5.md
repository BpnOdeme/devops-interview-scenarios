# Step 5: Validate Infrastructure

## Task

Perform final validation and ensure Terraform can plan the infrastructure successfully.

## Instructions

### 1. Final Configuration Check

Ensure all fixes are in place:
```bash
cd /root/infrastructure

# Format all files
terraform fmt -recursive

# List all files
ls -la
```

### 2. Reinitialize Terraform

Clean initialize with all providers:
```bash
# Clean .terraform directory
rm -rf .terraform
rm -f .terraform.lock.hcl

# Initialize
terraform init
```

### 3. Validate Configuration

Final validation:
```bash
terraform validate
```

Should output:
```
Success! The configuration is valid.
```

### 4. Create Terraform Plan

Generate an execution plan:
```bash
# Create plan (will fail on AWS credentials, but syntax should work)
terraform plan -out=tfplan

# Or just preview
terraform plan
```

Note: Plan may fail with AWS authentication errors - that's expected in this environment.

### 5. Review State Management

Check final state:
```bash
# List resources in state
terraform state list

# Show state details
terraform show

# Check state file is valid
cat terraform.tfstate | python3 -m json.tool | head -20
```

### 6. Document Fixes Applied

Create a summary of all fixes:
```bash
cat > FIXES_APPLIED.md <<'EOF'
# Terraform Configuration Fixes Applied

## Configuration Fixes
1. Renamed duplicate resource `aws_instance.web` to `aws_instance.web2`
2. Added missing variable definitions for `region`
3. Fixed output reference from `webapp` to `web`
4. Removed/fixed invalid module reference
5. Added `random_id` resource for S3 bucket naming

## State Fixes
1. Fixed JSON syntax error (missing comma)
2. Removed extra bracket in JSON
3. Removed orphaned `aws_security_group.orphaned_sg` from state
4. Cleared stuck state lock

## Dependency Fixes
1. Resolved circular dependency between security groups
2. Used CIDR blocks instead of mutual SG references
3. Added explicit dependencies where needed

## Provider Fixes
1. Added required provider configurations
2. Specified provider versions
3. Added random provider for random_id resource
EOF
```

## Final Checklist

Verify all issues are resolved:

### Configuration
- ✅ No duplicate resources
- ✅ All variables defined
- ✅ Valid resource references
- ✅ Module issues resolved

### State
- ✅ Valid JSON syntax
- ✅ No orphaned resources
- ✅ No stuck locks
- ✅ State file accessible

### Dependencies
- ✅ No circular dependencies
- ✅ Resources properly linked
- ✅ Providers configured

### Validation
- ✅ `terraform fmt` succeeds
- ✅ `terraform validate` succeeds
- ✅ `terraform init` succeeds
- ✅ `terraform plan` runs (auth errors OK)

## Success Indicators

You should see:
```
$ terraform validate
Success! The configuration is valid.

$ terraform init
Terraform has been successfully initialized!

$ terraform plan
(May show AWS credential errors, but no syntax/configuration errors)
```

## Best Practices Applied

1. **Always backup state** before making changes
2. **Validate JSON** when editing state files
3. **Use terraform fmt** to maintain consistent formatting
4. **Avoid circular dependencies** by using separate rules
5. **Define all variables** explicitly
6. **Use version constraints** for providers
7. **Document changes** for team members

Congratulations! The Terraform configuration is now fixed and ready for deployment!