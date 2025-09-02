#!/bin/bash

# Verify that the user has investigated the Nginx configuration
# Step 1 is about understanding the issues, not fixing them

# Check if nginx -t output was generated (it will fail due to errors)
if nginx -t 2>&1 | grep -q "test is successful"; then
    echo "Config valid"
    exit 0
else
    echo "Config has errors"
    exit 1
fi
