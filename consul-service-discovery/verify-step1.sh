#!/bin/bash

# Verify that the user has analyzed Consul issues
# Step 1 is about understanding the problems

# Check if docker ps was run to see container status
docker ps -a | grep -q consul && {
    echo "done"
    exit 0
}

echo "Please run 'docker ps -a' to check container status"
exit 1