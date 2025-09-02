#!/bin/bash

cd /root/microservices

# Check if docker-compose stack is running
if ! docker-compose ps | grep -q "Up"; then
    echo "Docker Compose stack is not running. Run: docker-compose up -d"
    exit 1
fi

# Count running services (should be 4)
RUNNING_COUNT=$(docker-compose ps | grep "Up" | wc -l)
if [ "$RUNNING_COUNT" -lt 4 ]; then
    echo "Not all services are running. Expected 4, found $RUNNING_COUNT"
    exit 1
fi

# Test API health endpoint
if ! curl -s http://localhost:3000/health | grep -q "healthy"; then
    echo "API health check failed"
    exit 1
fi

# Test frontend
if ! curl -s http://localhost/ | grep -q "html"; then
    echo "Frontend is not accessible"
    exit 1
fi

# Test frontend-to-API proxy
if ! curl -s http://localhost/api 2>/dev/null | grep -q "API"; then
    echo "Frontend cannot reach API through proxy"
    exit 1
fi

# Test database connectivity
if ! docker-compose exec -T db mysql -u appuser -papppass -e "SELECT 1;" >/dev/null 2>&1; then
    echo "Database connection failed"
    exit 1
fi

# Test Redis connectivity
if ! docker-compose exec -T cache redis-cli -a secretpass ping | grep -q "PONG"; then
    echo "Redis connection failed"
    exit 1
fi

echo "done"
exit 0