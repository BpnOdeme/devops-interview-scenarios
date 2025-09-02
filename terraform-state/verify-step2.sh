#!/bin/bash

cd /root/infrastructure

# Check if duplicate resource is fixed
if grep -c "resource \"aws_instance\" \"web\"" main.tf | grep -q "2"; then
    echo "Duplicate resource 'aws_instance.web' still exists"
    exit 1
fi

# Check if region variable is defined
if ! grep -q "variable \"region\"" variables.tf 2>/dev/null && ! grep -q "variable \"region\"" main.tf 2>/dev/null; then
    echo "Variable 'region' is not defined"
    exit 1
fi

# Check if output reference is fixed
if grep -q "aws_instance.webapp" main.tf; then
    echo "Invalid resource reference 'webapp' still exists in output"
    exit 1
fi

echo "done"
exit 0