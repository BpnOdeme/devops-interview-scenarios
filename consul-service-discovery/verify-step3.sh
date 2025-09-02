#!/bin/bash

# Check if services are registered
SERVICES=$(docker exec consul consul catalog services 2>/dev/null)

# Check for web service
if ! echo "$SERVICES" | grep -q "web"; then
    echo "Web service is not registered"
    exit 1
fi

# Check for API service
if ! echo "$SERVICES" | grep -q "api"; then
    echo "API service is not registered"
    exit 1
fi

# Check if services are accessible via API
if ! curl -s http://localhost:8500/v1/catalog/services | grep -q "web"; then
    echo "Services not accessible via API"
    exit 1
fi

echo "done"
exit 0