#!/bin/bash

# Check if Consul container is running
if ! docker ps | grep -q consul; then
    echo "Consul container is not running"
    exit 1
fi

# Check if Consul API is responding
if ! curl -s http://localhost:8500/v1/status/leader | grep -q "8300"; then
    echo "Consul API is not responding correctly"
    exit 1
fi

# Check if Consul members shows the server
if ! docker exec consul consul members 2>/dev/null | grep -q "alive"; then
    echo "Consul server is not showing as alive"
    exit 1
fi

echo "done"
exit 0