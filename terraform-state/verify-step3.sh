#!/bin/bash

cd /root/infrastructure

# Check if state file is valid JSON
if ! python3 -m json.tool terraform.tfstate > /dev/null 2>&1; then
    if ! jq . terraform.tfstate > /dev/null 2>&1; then
        echo "State file still has JSON syntax errors"
        exit 1
    fi
fi

# Check if lock file is removed
if [ -f .terraform/terraform.tfstate.lock.info ]; then
    echo "Lock file still exists"
    exit 1
fi

# Check if terraform init works
if ! terraform init > /dev/null 2>&1; then
    echo "Terraform initialization still fails"
    exit 1
fi

echo "done"
exit 0