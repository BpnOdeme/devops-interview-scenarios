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

# DB_HOST should be 'db' (the service name)
if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "DB_HOST.*db"; then
    echo "DB_HOST should be 'db' (the database service name)"
    exit 1
fi

# DB_PORT should be 3306 (MySQL default)
if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "DB_PORT.*3306"; then
    echo "DB_PORT should be '3306' (MySQL default port)"
    exit 1
fi

# REDIS_HOST should be 'cache' (the service name)
if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "REDIS_HOST.*cache"; then
    echo "REDIS_HOST should be 'cache' (the cache service name)"
    exit 1
fi

# REDIS_PORT should be 6379 (Redis default)
if ! echo "$CONFIG" | grep -A 50 "^  api:" | grep -q "REDIS_PORT.*6379"; then
    echo "REDIS_PORT should be '6379' (Redis default port)"
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
if ! echo "$CONFIG" | grep -A 20 "^  cache:" | grep -E "6379.*6379|published.*6379.*target.*6379" > /dev/null; then
    echo "Redis port mapping should be 6379:6379 (host:container)"
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
    # Check if nginx proxies to 'api' service (not wrong names like 'api-server')
    # and to port 3000 (not wrong ports like 3001)
    if ! grep -E "proxy_pass.*http://api:3000" nginx/default.conf > /dev/null; then
        echo "Nginx configuration should proxy to 'http://api:3000'"
        echo "Current proxy_pass configuration:"
        grep "proxy_pass" nginx/default.conf || echo "(no proxy_pass found)"
        exit 1
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
