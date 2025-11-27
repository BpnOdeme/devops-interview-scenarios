#!/bin/bash

# Step 3 Verification: Check service configurations (env vars, ports, volumes, nginx config)

cd /root/microservices

# Check if API index.js exists and has content
if [ ! -f api/index.js ] || [ ! -s api/index.js ]; then
    echo "API index.js file is missing or empty"
    exit 1
fi

# Check if nginx config exists
if [ ! -f nginx/default.conf ]; then
    echo "Nginx configuration file is missing"
    exit 1
fi

# Parse docker-compose config
CONFIG=$(docker-compose config 2>/dev/null)

if [ -z "$CONFIG" ]; then
    echo "Failed to parse docker-compose.yml"
    exit 1
fi

# Check API environment variables
echo "Checking API environment variables..."

# Extract actual service names from docker-compose
DB_SERVICE=$(echo "$CONFIG" | grep -E "^  [a-z_-]+:" | grep -i "db\|mysql\|database" | head -1 | tr -d ' :' || echo "db")
CACHE_SERVICE=$(echo "$CONFIG" | grep -E "^  [a-z_-]+:" | grep -i "cache\|redis" | head -1 | tr -d ' :' || echo "cache")

# Get DB_HOST from API config
API_DB_HOST=$(echo "$CONFIG" | grep -A 50 "^  api:" | grep "DB_HOST" | head -1 | cut -d: -f2 | tr -d ' ')
if [ -z "$API_DB_HOST" ]; then
    echo "DB_HOST environment variable is missing in API service"
    exit 1
fi

# Verify DB_HOST matches a database service name
if ! echo "$CONFIG" | grep -E "^  ${API_DB_HOST}:" > /dev/null; then
    echo "DB_HOST '$API_DB_HOST' does not match any service defined in docker-compose.yml"
    echo "Available services: $(echo "$CONFIG" | grep -E "^  [a-z_-]+:" | tr -d ' :' | tr '\n' ', ')"
    exit 1
fi

# Get DB_PORT from API config and verify it's set
API_DB_PORT=$(echo "$CONFIG" | grep -A 50 "^  api:" | grep "DB_PORT" | head -1 | cut -d: -f2 | tr -d ' ')
if [ -z "$API_DB_PORT" ]; then
    echo "DB_PORT environment variable is missing in API service"
    exit 1
fi

# Get REDIS_HOST from API config
API_REDIS_HOST=$(echo "$CONFIG" | grep -A 50 "^  api:" | grep "REDIS_HOST" | head -1 | cut -d: -f2 | tr -d ' ')
if [ -z "$API_REDIS_HOST" ]; then
    echo "REDIS_HOST environment variable is missing in API service"
    exit 1
fi

# Verify REDIS_HOST matches a cache service name
if ! echo "$CONFIG" | grep -E "^  ${API_REDIS_HOST}:" > /dev/null; then
    echo "REDIS_HOST '$API_REDIS_HOST' does not match any service defined in docker-compose.yml"
    echo "Available services: $(echo "$CONFIG" | grep -E "^  [a-z_-]+:" | tr -d ' :' | tr '\n' ', ')"
    exit 1
fi

# Get REDIS_PORT from API config and verify it's set
API_REDIS_PORT=$(echo "$CONFIG" | grep -A 50 "^  api:" | grep "REDIS_PORT" | head -1 | cut -d: -f2 | tr -d ' ')
if [ -z "$API_REDIS_PORT" ]; then
    echo "REDIS_PORT environment variable is missing in API service"
    exit 1
fi

# Check if DB_USER, DB_PASSWORD, DB_NAME exist in API config
if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "DB_USER"; then
    echo "DB_USER environment variable is missing in API service"
    exit 1
fi

if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "DB_PASSWORD"; then
    echo "DB_PASSWORD environment variable is missing in API service"
    exit 1
fi

if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "DB_NAME"; then
    echo "DB_NAME environment variable is missing in API service"
    exit 1
fi

# Check if REDIS_PASSWORD exists
if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "REDIS_PASSWORD"; then
    echo "REDIS_PASSWORD environment variable is missing in API service"
    exit 1
fi

# Check MySQL environment variables
echo "Checking database configuration..."

if ! echo "$CONFIG" | grep -A 30 "^  db:" | grep -q "MYSQL_USER"; then
    echo "MYSQL_USER is not defined in database service"
    exit 1
fi

if ! echo "$CONFIG" | grep -A 30 "^  db:" | grep -q "MYSQL_PASSWORD"; then
    echo "MYSQL_PASSWORD is not defined in database service"
    exit 1
fi

if ! echo "$CONFIG" | grep -A 30 "^  db:" | grep -q "MYSQL_DATABASE"; then
    echo "MYSQL_DATABASE is not defined in database service"
    exit 1
fi

# Check port mappings (host:container format)
echo "Checking port mappings..."

# Redis/cache port should be 6379:6379 (not reversed)
CACHE_CONFIG=$(echo "$CONFIG" | grep -A 20 "^  cache:")
if ! echo "$CACHE_CONFIG" | grep -q "published.*6379" || ! echo "$CACHE_CONFIG" | grep -q "target.*6379"; then
    echo "Redis port mapping should be 6379:6379 (host:container)"
    echo "Current cache port configuration:"
    echo "$CACHE_CONFIG" | grep -E "published|target" || echo "(no port mapping found)"
    exit 1
fi

# Check if API has volume mount for code
echo "Checking volume mounts..."

# API service must have ./api:/app volume mount (or similar)
if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -E "api:/app|/root/microservices/api:/app|\./api:/app" > /dev/null; then
    echo "API service is missing volume mount for application code (./api:/app)"
    exit 1
fi

# Check nginx proxy configuration
echo "Checking nginx configuration..."

if [ -f nginx/default.conf ]; then
    # Extract proxy_pass configuration
    PROXY_PASS=$(grep "proxy_pass" nginx/default.conf | head -1 | sed 's/.*proxy_pass[[:space:]]*//;s/;.*//' || echo "")

    if [ -z "$PROXY_PASS" ]; then
        echo "No proxy_pass directive found in nginx/default.conf"
        exit 1
    fi

    # Extract service name and port from proxy_pass (e.g., http://api:3000 -> api, 3000)
    NGINX_API_SERVICE=$(echo "$PROXY_PASS" | sed 's|http://||;s|:.*||')
    NGINX_API_PORT=$(echo "$PROXY_PASS" | sed 's|.*:||;s|/.*||')

    # Verify the service exists in docker-compose
    if ! echo "$CONFIG" | grep -E "^  ${NGINX_API_SERVICE}:" > /dev/null; then
        echo "Nginx proxies to '$NGINX_API_SERVICE' but this service doesn't exist in docker-compose.yml"
        echo "Available services: $(echo "$CONFIG" | grep -E "^  [a-z_-]+:" | tr -d ' :' | tr '\n' ', ')"
        exit 1
    fi

    # Verify the port matches what the API service exposes
    API_CONTAINER_PORT=$(echo "$CONFIG" | grep -A 20 "^  ${NGINX_API_SERVICE}:" | grep -E "target:|[0-9]+:[0-9]+" | head -1 | sed 's/.*[^0-9]\([0-9]\+\)$/\1/')

    if [ ! -z "$API_CONTAINER_PORT" ] && [ "$NGINX_API_PORT" != "$API_CONTAINER_PORT" ]; then
        echo "Warning: Nginx proxies to port $NGINX_API_PORT but API service exposes port $API_CONTAINER_PORT"
        echo "This may cause connection issues"
    fi
else
    echo "nginx/default.conf is missing"
    exit 1
fi

# Cross-check credentials between API and DB
echo "Cross-checking credentials..."

# Extract DB credentials from API env
API_DB_USER=$(echo "$CONFIG" | grep -A 50 "^  api:" | grep "DB_USER" | head -1 | cut -d: -f2 | tr -d ' ')
API_DB_PASS=$(echo "$CONFIG" | grep -A 50 "^  api:" | grep "DB_PASSWORD" | head -1 | cut -d: -f2 | tr -d ' ')

# Extract MySQL credentials from DB env
MYSQL_USER=$(echo "$CONFIG" | grep -A 30 "^  db:" | grep "MYSQL_USER" | head -1 | cut -d: -f2 | tr -d ' ')
MYSQL_PASS=$(echo "$CONFIG" | grep -A 30 "^  db:" | grep "MYSQL_PASSWORD" | head -1 | cut -d: -f2 | tr -d ' ')

# Verify they match
if [ "$API_DB_USER" != "$MYSQL_USER" ]; then
    echo "Credential mismatch: API's DB_USER ($API_DB_USER) doesn't match DB's MYSQL_USER ($MYSQL_USER)"
    exit 1
fi

if [ "$API_DB_PASS" != "$MYSQL_PASS" ]; then
    echo "Credential mismatch: API's DB_PASSWORD doesn't match DB's MYSQL_PASSWORD"
    exit 1
fi

echo "done"
exit 0
