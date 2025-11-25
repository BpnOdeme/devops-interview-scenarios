#!/bin/bash

# Step 2 Verification: Check if network configuration is fixed

cd /root/microservices

# Check if configuration is valid YAML
if ! docker-compose config >/dev/null 2>&1; then
    echo "Docker Compose configuration has syntax errors. Run: docker-compose config"
    exit 1
fi

# Extract network configuration
CONFIG=$(docker-compose config 2>/dev/null)

# Extract network assignments for each service
FRONTEND_NETS=$(echo "$CONFIG" | grep -A 30 "^  frontend:" | grep -A 10 "networks:" | grep -E "^\s+[a-z]" | grep -v "networks:" | tr -d ' -' | head -5)
API_NETS=$(echo "$CONFIG" | grep -A 30 "^  api:" | grep -A 10 "networks:" | grep -E "^\s+[a-z]" | grep -v "networks:" | tr -d ' -' | head -5)
DB_NETS=$(echo "$CONFIG" | grep -A 30 "^  db:" | grep -A 10 "networks:" | grep -E "^\s+[a-z]" | grep -v "networks:" | tr -d ' -' | head -5)
CACHE_NETS=$(echo "$CONFIG" | grep -A 30 "^  cache:" | grep -A 10 "networks:" | grep -E "^\s+[a-z]" | grep -v "networks:" | tr -d ' -' | head -5)

# Check if at least one common network exists between API and its dependencies
COMMON_NET=false

for api_net in $API_NETS; do
    # Check if db is on the same network
    if echo "$DB_NETS" | grep -q "$api_net"; then
        # Check if cache is also on this network
        if echo "$CACHE_NETS" | grep -q "$api_net"; then
            COMMON_NET=true
            break
        fi
    fi
done

if [ "$COMMON_NET" = false ]; then
    echo "Network configuration issue: API, DB, and Cache must share at least one common network"
    echo "Current API networks: $API_NETS"
    echo "Current DB networks: $DB_NETS"
    echo "Current Cache networks: $CACHE_NETS"
    exit 1
fi

# Check if frontend and API share a network (for proxy to work)
FRONTEND_API_COMMON=false

for frontend_net in $FRONTEND_NETS; do
    if echo "$API_NETS" | grep -q "$frontend_net"; then
        FRONTEND_API_COMMON=true
        break
    fi
done

if [ "$FRONTEND_API_COMMON" = false ]; then
    echo "Network configuration issue: Frontend and API must share at least one common network"
    echo "Current Frontend networks: $FRONTEND_NETS"
    echo "Current API networks: $API_NETS"
    exit 1
fi

# Check network driver (should be bridge, not overlay)
OVERLAY_COUNT=$(echo "$CONFIG" | grep -A 5 "^networks:" | grep "driver: overlay" | wc -l)

if [ "$OVERLAY_COUNT" -gt 0 ]; then
    echo "Network driver issue: Using 'overlay' driver requires Docker Swarm. Use 'bridge' for single-host deployments"
    exit 1
fi

echo "done"
exit 0
