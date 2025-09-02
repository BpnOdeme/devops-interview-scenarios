#!/bin/bash

echo "Welcome to Terraform State and Configuration Troubleshooting!"
echo ""
echo "Checking Terraform installation..."

if terraform version >/dev/null 2>&1; then
    echo "[✓] Terraform is installed: $(terraform version | head -1)"
else
    echo "[✗] Terraform is NOT installed"
fi

echo ""
echo "Checking project structure..."
cd /root/infrastructure 2>/dev/null || echo "[!] Project directory not found"

echo ""
echo "Current directory contents:"
ls -la

echo ""
echo "Checking Terraform configuration..."
echo ""

# Try to validate (will fail)
echo "Running 'terraform validate'..."
terraform validate 2>&1 | head -10

echo ""
echo "[!] Multiple issues detected:"
echo "    - Configuration has syntax errors"
echo "    - State file is corrupted"
echo "    - Duplicate resources defined"
echo "    - Circular dependencies exist"
echo "    - State lock may be stuck"
echo ""
echo "Your first task: Analyze and understand all the issues"
echo "Start with: terraform validate"
echo ""
echo "Working directory: /root/infrastructure"