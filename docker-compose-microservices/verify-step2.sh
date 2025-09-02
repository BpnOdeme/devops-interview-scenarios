#!/bin/bash

# Check if docker-compose.yml has correct network configuration
cd /root/microservices

# Check if configuration is valid
if ! docker-compose config >/dev/null 2>&1; then
    echo "Docker Compose configuration has syntax errors"
    exit 1
fi

# Check if all services are on the same network or properly connected
CONFIG=$(docker-compose config 2>/dev/null)

# Extract network configuration for each service
FRONTEND_NETS=$(echo "$CONFIG" | grep -A 20 "frontend:" | grep -A 5 "networks:" | grep -E "^\s+-" | tr -d ' -')
API_NETS=$(echo "$CONFIG" | grep -A 20 "api:" | grep -A 5 "networks:" | grep -E "^\s+-" | tr -d ' -')
DB_NETS=$(echo "$CONFIG" | grep -A 20 "db:" | grep -A 5 "networks:" | grep -E "^\s+-" | tr -d ' -')
CACHE_NETS=$(echo "$CONFIG" | grep -A 20 "cache:" | grep -A 5 "networks:" | grep -E "^\s+-" | tr -d ' -')

# Check if there's at least one common network between API and other services
COMMON_NET=false

for net in $API_NETS; do
    if echo "$DB_NETS" | grep -q "$net" && echo "$CACHE_NETS" | grep -q "$net"; then
        COMMON_NET=true
        break
    fi
done

if [ "$COMMON_NET" = true ]; then
    echo "done"
    exit 0
else
    echo "Services are not on the same network. API, DB, and Cache must share at least one network."
    exit 1
fi