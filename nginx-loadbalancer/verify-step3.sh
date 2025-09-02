#!/bin/bash

# Test if load balancer is working
RESPONSES=$(for i in {1..10}; do curl -s http://localhost/ 2>/dev/null | grep -o "Backend Server [0-9]"; done)

# Count unique backends
UNIQUE_BACKENDS=$(echo "$RESPONSES" | sort -u | wc -l)

# Check if we get responses from at least 2 backends
if [ "$UNIQUE_BACKENDS" -ge 2 ]; then
    # Check if health endpoint works
    if curl -s http://localhost/health | grep -q "healthy"; then
        echo "done"
        exit 0
    else
        echo "Load balancing works but health endpoint is not responding correctly"
        exit 1
    fi
else
    echo "Load balancer is not distributing traffic to multiple backends"
    exit 1
fi