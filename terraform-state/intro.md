# Terraform State and Configuration Troubleshooting

## Scenario Overview

You've been called to fix a critical infrastructure-as-code deployment that has multiple issues. The previous engineer left the Terraform configuration in a broken state with corrupted state files, configuration errors, and dependency problems. Production deployment is blocked until these issues are resolved.

## The Situation

The infrastructure team reports:
- ❌ Terraform state file is corrupted
- ❌ Configuration has syntax errors
- ❌ Duplicate resource definitions
- ❌ Circular dependencies between resources
- ❌ Backend configuration incomplete
- ❌ State lock is stuck
- ❌ Module sources are broken

## Your Mission

1. **Diagnose State Issues**: Identify and understand all state-related problems
2. **Fix Configuration Errors**: Resolve syntax and logical errors in the Terraform files
3. **Resolve State Conflicts**: Fix the corrupted state and handle conflicts
4. **Fix Dependencies**: Resolve circular dependencies and module issues
5. **Validate Infrastructure**: Ensure Terraform can plan and apply successfully

## Available Tools

- `terraform` - Infrastructure as Code tool
- `terraform init` - Initialize Terraform
- `terraform validate` - Validate configuration
- `terraform plan` - Preview changes
- `terraform state` - Manage state
- `nano/vim` - Edit configuration files

## Key Files

- `/root/infrastructure/main.tf` - Main Terraform configuration
- `/root/infrastructure/terraform.tfstate` - State file (corrupted)
- `/root/infrastructure/.terraform.lock.hcl` - Lock file

## Success Criteria

- State file is valid and consistent
- No configuration syntax errors
- No duplicate resources
- No circular dependencies
- Backend properly configured
- Terraform plan executes successfully

## Common Terraform Commands

```bash
# Check Terraform version
terraform version

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format configuration
terraform fmt

# Show current state
terraform state list

# Remove item from state
terraform state rm <resource>

# Import existing resource
terraform import <resource> <id>

# Force unlock state
terraform force-unlock <lock-id>
```

## Important Notes

- Always backup state files before making changes
- Use `terraform plan` to preview changes before applying
- State manipulation should be done carefully
- Document all fixes for the team

Click **START** to begin troubleshooting!