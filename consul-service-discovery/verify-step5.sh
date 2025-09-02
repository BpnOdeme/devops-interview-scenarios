#!/bin/bash

# Check if DNS service discovery works
DNS_RESULT=$(dig +short @127.0.0.1 -p 8600 web.service.consul 2>/dev/null)
if [ -z "$DNS_RESULT" ]; then
    echo "DNS service discovery not working for web service"
    exit 1
fi

# Check if API returns services
API_SERVICES=$(curl -s http://localhost:8500/v1/catalog/services 2>/dev/null)
if ! echo "$API_SERVICES" | grep -q "web"; then
    echo "API not returning web service"
    exit 1
fi

if ! echo "$API_SERVICES" | grep -q "api"; then
    echo "API not returning api service"
    exit 1
fi

# Check if at least one service is healthy
HEALTHY=$(curl -s http://localhost:8500/v1/health/state/passing 2>/dev/null | jq 'length')
if [ "$HEALTHY" -lt 1 ]; then
    echo "No healthy services found"
    exit 1
fi

echo "done"
exit 0