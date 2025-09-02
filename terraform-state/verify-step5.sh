#!/bin/bash

cd /root/infrastructure

# Final comprehensive check
ERRORS=0

# Check if Terraform validates
if ! terraform validate > /dev/null 2>&1; then
    echo "Terraform validation failed"
    ERRORS=$((ERRORS + 1))
fi

# Check if state file is valid JSON
if ! python3 -m json.tool terraform.tfstate > /dev/null 2>&1; then
    echo "State file is not valid JSON"
    ERRORS=$((ERRORS + 1))
fi

# Check if init works
if ! terraform init > /dev/null 2>&1; then
    echo "Terraform init failed"
    ERRORS=$((ERRORS + 1))
fi

# Check for circular dependencies
if terraform validate 2>&1 | grep -q "Cycle"; then
    echo "Circular dependencies still exist"
    ERRORS=$((ERRORS + 1))
fi

# Check for duplicate resources
if grep -c "resource \"aws_instance\" \"web\"" main.tf 2>/dev/null | grep -q "2"; then
    echo "Duplicate resources still exist"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
    echo "done"
    exit 0
else
    echo "Found $ERRORS issues remaining"
    exit 1
fi