#!/bin/bash

# Step 4 Verification: End-to-end testing of the complete stack

cd /root/microservices

echo "Verifying Docker Compose stack is running..."

# Check if docker-compose stack is running
if ! docker-compose ps | grep -q "Up"; then
    echo "Docker Compose stack is not running. Run: docker-compose up -d"
    exit 1
fi

# Count running services (should be 4: frontend, api, db, cache)
RUNNING_COUNT=$(docker-compose ps | grep "Up" | wc -l)
if [ "$RUNNING_COUNT" -lt 4 ]; then
    echo "Not all services are running. Expected 4 (frontend, api, db, cache), found $RUNNING_COUNT"
    echo "Current status:"
    docker-compose ps
    exit 1
fi

echo "All services are running. Testing connectivity..."

# Test API health endpoint
echo "Testing API health endpoint..."
API_HEALTH=$(curl -s http://localhost:3000/health 2>/dev/null)

if ! echo "$API_HEALTH" | grep -q "healthy"; then
    echo "API health check failed. Expected 'healthy' in response"
    echo "Got: $API_HEALTH"
    exit 1
fi

# Test frontend
echo "Testing frontend..."
if ! curl -s http://localhost/ 2>/dev/null | grep -qi "html"; then
    echo "Frontend is not accessible or not returning HTML"
    exit 1
fi

# Test frontend-to-API proxy (critical end-to-end test)
echo "Testing frontend-to-API proxy..."
PROXY_RESPONSE=$(curl -s http://localhost/api 2>/dev/null)

if ! echo "$PROXY_RESPONSE" | grep -q "API"; then
    echo "Frontend cannot reach API through proxy"
    echo "Expected response containing 'API', got: $PROXY_RESPONSE"
    echo ""
    echo "This could indicate:"
    echo "- Nginx proxy_pass configuration is wrong"
    echo "- Services are on different networks"
    echo "- API service name mismatch"
    exit 1
fi

# Test database connectivity
echo "Testing database connectivity..."
if ! docker-compose exec -T db mysql -u appuser -papppass -e "SELECT 1;" >/dev/null 2>&1; then
    echo "Database connection failed"
    echo "This could indicate:"
    echo "- Wrong database credentials"
    echo "- MYSQL_USER not created"
    echo "- Database not fully initialized"
    exit 1
fi

# Verify appdb database exists
echo "Verifying appdb database exists..."
if ! docker-compose exec -T db mysql -u appuser -papppass -e "USE appdb; SELECT 1;" >/dev/null 2>&1; then
    echo "appdb database does not exist or is not accessible"
    exit 1
fi

# Test Redis connectivity
echo "Testing Redis connectivity..."
REDIS_PING=$(docker-compose exec -T cache redis-cli -a secretpass ping 2>/dev/null)

if ! echo "$REDIS_PING" | grep -q "PONG"; then
    echo "Redis connection failed"
    echo "Expected: PONG"
    echo "Got: $REDIS_PING"
    exit 1
fi

# Verify API can connect to database (check logs)
echo "Checking API database connection in logs..."

# FIRST: Check if API successfully connected (most recent state matters)
if docker-compose logs api 2>/dev/null | grep -q "Connected to MySQL database"; then
    echo "✓ API connected to MySQL successfully"
else
    # If no success message, then check for connection errors
    if docker-compose logs api 2>/dev/null | grep -qi "Error: connect ECONNREFUSED.*3306\|ENOTFOUND db\|ER_ACCESS_DENIED_ERROR\|Can't connect to MySQL"; then
        echo "API has database connection errors. Check logs:"
        docker-compose logs api | tail -20
        exit 1
    else
        echo "API has not connected to MySQL database yet"
        echo "Expected to see: 'Connected to MySQL database' in logs"
        docker-compose logs api | tail -20
        exit 1
    fi
fi

# Verify API can connect to Redis (check logs)
echo "Checking API Redis connection in logs..."

# FIRST: Check if API successfully connected (most recent state matters)
if docker-compose logs api 2>/dev/null | grep -q "Connected to Redis"; then
    echo "✓ API connected to Redis successfully"
else
    # If no success message, then check for connection errors
    if docker-compose logs api 2>/dev/null | grep -qi "Error: connect ECONNREFUSED.*6379\|ENOTFOUND cache\|Redis connection.*failed"; then
        echo "API has Redis connection errors. Check logs:"
        docker-compose logs api | tail -20
        exit 1
    else
        echo "API has not connected to Redis yet"
        echo "Expected to see: 'Connected to Redis' in logs"
        docker-compose logs api | tail -20
        exit 1
    fi
fi

# Test network connectivity between services
echo "Testing inter-service network connectivity..."

# Frontend can reach API
if ! docker-compose exec -T frontend ping -c 1 -W 2 api >/dev/null 2>&1; then
    echo "Frontend cannot ping API - network connectivity issue"
    exit 1
fi

# API can reach database
if ! docker-compose exec -T api ping -c 1 -W 2 db >/dev/null 2>&1; then
    echo "API cannot ping database - network connectivity issue"
    exit 1
fi

# API can reach cache
if ! docker-compose exec -T api ping -c 1 -W 2 cache >/dev/null 2>&1; then
    echo "API cannot ping cache - network connectivity issue"
    exit 1
fi

# Final comprehensive check: API should have successfully started
echo "Verifying API startup..."

# FIRST: Check if API successfully started (most recent state matters)
if docker-compose logs api 2>/dev/null | grep -q "API server listening on port 3000"; then
    echo "✓ API server started successfully"
else
    # If no success message, then check for crash/fatal errors
    if docker-compose logs api 2>/dev/null | grep -qi "Error.*Cannot start\|Application.*crashed\|Unhandled rejection\|process exited"; then
        echo "API may have crashed or failed to start properly. Check logs:"
        docker-compose logs api | tail -30
        exit 1
    else
        echo "API has not started yet or startup message not found"
        echo "Expected to see: 'API server listening on port 3000' in logs"
        docker-compose logs api | tail -30
        exit 1
    fi
fi

# Check if API server is listening on port 3000
echo "Verifying API is listening on port 3000..."
if ! docker-compose exec -T api wget -q -O- http://localhost:3000/health 2>/dev/null | grep -q "healthy"; then
    echo "API is not responding on port 3000 from inside the container"
    exit 1
fi

echo "✅ All tests passed!"
echo ""
echo "Summary of successful tests:"
echo "  ✓ All 4 services are running"
echo "  ✓ API health check returns healthy status"
echo "  ✓ Frontend serves HTML content"
echo "  ✓ Frontend successfully proxies /api requests to backend"
echo "  ✓ Database accepts connections with correct credentials"
echo "  ✓ appdb database exists and is accessible"
echo "  ✓ Redis responds to authenticated ping"
echo "  ✓ API has no connection errors in logs"
echo "  ✓ All services can communicate over Docker network"
echo "  ✓ API is listening and responding on port 3000"
echo ""
echo "done"
exit 0
