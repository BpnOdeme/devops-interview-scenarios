#!/bin/bash

# Verify that the user has analyzed the Terraform issues
# Step 1 is about understanding the problems

cd /root/infrastructure 2>/dev/null

# Check if terraform validate was run (it will fail but that's expected)
terraform validate 2>&1 | grep -q "Error" && {
    echo "done"
    exit 0
}

echo "Please run 'terraform validate' to see the configuration errors"
exit 1