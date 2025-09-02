#!/bin/bash

# Verify that the user has investigated the Nginx configuration
# Step 1 is about understanding the issues, not fixing them

# Check if nginx -t output was generated (it will fail due to errors)
nginx -t 2>&1 | grep -q "nginx: \[" && {
    echo "done"
    exit 0
}

# If we reach here, nginx -t hasn't been run or has different output
echo "Please run 'nginx -t' to check the Nginx configuration for errors"
exit 1