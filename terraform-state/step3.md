# Step 3: Resolve State Conflicts

## Task

Fix the corrupted state file and resolve state-related issues.

## Instructions

### 1. Backup Current State

First, always backup the state:
```bash
cp terraform.tfstate terraform.tfstate.broken
cp terraform.tfstate.backup terraform.tfstate.original
```

### 2. Fix JSON Syntax in State File

The state file has JSON syntax errors. Fix them:

```bash
nano terraform.tfstate
```

Find and fix:
- Missing comma after `"instance_type": "t2.micro"`
- Remove extra closing bracket at the end

Corrected JSON structure:
```json
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
            "instance_type": "t2.micro",  // ADD COMMA HERE
            "tags": {
              "Name": "OldWebServer"
            },
            "public_ip": "54.123.456.789"
          },
          "private": "corrupted_data"
        }
      ]
    }
  ]  // REMOVE EXTRA BRACKET
}
```

### 3. Validate JSON

Check if JSON is valid:
```bash
python3 -m json.tool terraform.tfstate > /dev/null && echo "JSON is valid" || echo "JSON has errors"
```

Or use jq if available:
```bash
jq . terraform.tfstate > /dev/null && echo "JSON is valid" || echo "JSON has errors"
```

### 4. Remove Orphaned Resources from State

Remove resources that no longer exist in configuration:
```bash
# List current state
terraform state list

# Remove orphaned security group
terraform state rm aws_security_group.orphaned_sg
```

### 5. Handle State Lock

If there's a stuck lock, remove it:
```bash
# Check for lock file
ls -la .terraform/terraform.tfstate.lock.info

# Remove the lock file
rm -f .terraform/terraform.tfstate.lock.info
```

Or force unlock if you have the lock ID:
```bash
terraform force-unlock <LOCK_ID>
```

### 6. Reinitialize Terraform

After fixing state issues:
```bash
# Remove .terraform directory
rm -rf .terraform

# Reinitialize
terraform init
```

### 7. Refresh State

Sync state with actual infrastructure (in our case, simulate):
```bash
# This would normally sync with real infrastructure
# terraform refresh

# For this exercise, just validate state
terraform state list
```

## Alternative: Start Fresh

If state is too corrupted, start fresh:
```bash
# Move corrupted state
mv terraform.tfstate terraform.tfstate.corrupted

# Start with empty state
echo '{"version":4,"terraform_version":"1.5.0","resources":[]}' > terraform.tfstate

# Or copy from backup
cp terraform.tfstate.backup terraform.tfstate
```

## Validation

Check state is working:
```bash
# List resources in state
terraform state list

# Show state file
terraform show

# Validate configuration with state
terraform plan
```

## Checklist

- [ ] Backed up state files
- [ ] Fixed JSON syntax errors in state
- [ ] Removed orphaned resources
- [ ] Cleared stuck lock
- [ ] Reinitialized Terraform
- [ ] Validated state is working