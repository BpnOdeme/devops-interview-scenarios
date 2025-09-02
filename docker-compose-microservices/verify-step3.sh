#!/bin/bash

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

# Check API environment variables
if ! echo "$CONFIG" | grep -q "DB_HOST: db"; then
    echo "DB_HOST should be 'db'"
    exit 1
fi

if ! echo "$CONFIG" | grep -q "DB_PORT: ['\"]3306['\"]"; then
    echo "DB_PORT should be '3306'"
    exit 1
fi

if ! echo "$CONFIG" | grep -q "REDIS_HOST: cache"; then
    echo "REDIS_HOST should be 'cache'"
    exit 1
fi

# Check if MYSQL_USER is defined
if ! echo "$CONFIG" | grep -q "MYSQL_USER:"; then
    echo "MYSQL_USER is not defined in database service"
    exit 1
fi

# Check Redis port mapping
if ! echo "$CONFIG" | grep -A 5 "cache:" | grep -q "6379:6379"; then
    echo "Redis port mapping should be 6379:6379"
    exit 1
fi

# Check if API has volume mount
if ! echo "$CONFIG" | grep -A 10 "api:" | grep -q "./api:/app"; then
    echo "API service is missing volume mount for application code"
    exit 1
fi

echo "done"
exit 0