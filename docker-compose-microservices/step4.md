# Step 4: Deploy and Test the Complete Stack

## Objective

Start the Docker Compose stack and perform comprehensive end-to-end testing to verify all services are working correctly and can communicate with each other.

## Background

Configuration without validation is worthless. As a DevOps engineer, you must not only fix issues but also verify that your solutions work. This step teaches you systematic testing methodologies for distributed systems.

## Prerequisites

Before starting this step, ensure:
- All configuration files have been fixed (Steps 1-3 completed)
- `docker-compose config` passes without errors
- All necessary files exist (api/index.js, nginx/default.conf, etc.)

## Tasks

### 1. Pre-Flight Checks

Before deploying, perform final validation:

```bash
cd /root/microservices

# Validate YAML syntax
docker-compose config > /dev/null && echo "✓ Configuration is valid" || echo "✗ Configuration has errors"

# Check if all required files exist
test -f api/index.js && echo "✓ API code exists" || echo "✗ API code missing"
test -f nginx/default.conf && echo "✓ Nginx config exists" || echo "✗ Nginx config missing"
test -f html/index.html && echo "✓ Frontend HTML exists" || echo "✗ Frontend HTML missing"
```

**If any checks fail, go back and fix the issues before proceeding.**

### 2. Clean Start

Ensure no previous containers or networks are interfering:

```bash
# Stop any running containers from previous attempts
docker-compose down 2>/dev/null || true

# Remove any conflicting Docker networks
docker network rm backend-net 2>/dev/null || true
docker network rm frontend-net 2>/dev/null || true
docker network rm db-net 2>/dev/null || true
docker network rm cache-net 2>/dev/null || true
```

### 3. Start the Stack

Launch all services in detached mode:

```bash
docker-compose up -d
```

**Expected output**: You should see Docker pulling images (if needed) and creating containers for all four services.

**Note**: The API container will automatically run `npm install` on startup, so it may take a minute to become fully ready. This is normal.

### 4. Monitor Startup

Watch the services come online:

```bash
# Check service status
docker-compose ps

# Watch logs in real-time
docker-compose logs -f
```

**What to look for:**
- All services should eventually show "Up" status
- API should connect to database and Redis successfully
- No repeated error messages in logs
- Database should initialize successfully
- Redis should start accepting connections

**Use Ctrl+C to stop following logs.**

### 5. Service-Level Health Checks

Verify each service individually:

#### Check Container Status
```bash
docker-compose ps
```

**Expected result**: All services show "Up" status (not "Restarting" or "Exit")

#### Check Service Logs for Errors
```bash
# API logs - should show successful connections
docker-compose logs api | tail -20

# Database logs - should show MySQL ready
docker-compose logs db | tail -20

# Cache logs - should show Redis ready
docker-compose logs cache | tail -20

# Frontend logs - should show nginx started
docker-compose logs frontend | tail -20
```

**Red flags:**
- Connection refused errors
- Authentication failures
- Port binding errors
- Module not found errors

### 6. Test Database Connectivity

Verify the database is accessible and configured correctly:

```bash
# Test database connection with application user
docker-compose exec db mysql -u appuser -papppass -e "SELECT 1 AS test;"

# Check if database exists
docker-compose exec db mysql -u appuser -papppass -e "SHOW DATABASES;"

# Verify appdb database exists
docker-compose exec db mysql -u appuser -papppass -e "USE appdb; SELECT DATABASE();"
```

**Expected result**: Commands should succeed without authentication errors. The `appdb` database should exist.

### 7. Test Redis Connectivity

Verify Redis is accessible with authentication:

```bash
# Test Redis connection with password
docker-compose exec cache redis-cli -a secretpass ping

# Check Redis info
docker-compose exec cache redis-cli -a secretpass info server | head -10
```

**Expected result**: `PONG` response indicates successful connection.

### 8. Test API Endpoints

Verify the API service is responding:

#### Health Check Endpoint
```bash
curl -s http://localhost:3000/health
```

**Expected response:**
```json
{"status":"healthy","service":"api"}
```

#### Root API Endpoint
```bash
curl -s http://localhost:3000/
```

**Expected response:**
```json
{"message":"API is running!"}
```

#### Direct API Endpoint
```bash
curl -s http://localhost:3000/api
```

**Expected response:**
```json
{"message":"API is working!"}
```

### 9. Test Frontend

Verify the frontend is serving content:

```bash
# Test frontend root
curl -s http://localhost/ | head -10

# Should return HTML content
```

**Expected result**: HTML content from html/index.html should be returned.

### 10. Test Frontend-to-API Proxy

This is the critical end-to-end test - verifying nginx correctly proxies requests to the API:

```bash
curl -s http://localhost/api
```

**Expected response:**
```json
{"message":"API is working!"}
```

**This proves:**
- Frontend (nginx) is running
- Nginx configuration is correct
- Nginx can resolve the API service name via Docker DNS
- Network connectivity exists between frontend and API
- API is responding to requests

### 11. Test Inter-Service Network Connectivity

Verify services can reach each other over the Docker network:

```bash
# API can ping database
docker-compose exec api ping -c 2 db

# API can ping cache
docker-compose exec api ping -c 2 cache

# Frontend can ping API
docker-compose exec frontend ping -c 2 api
```

**Expected result**: All ping commands should succeed with 0% packet loss.

### 12. Verify Database Connections from API

Check if the API can actually connect to its dependencies:

```bash
# Check API logs for successful database connection
docker-compose logs api | grep -i "mysql\|database\|connected"

# Check API logs for successful Redis connection
docker-compose logs api | grep -i "redis\|cache\|connected"
```

**Expected result**: You should see log messages indicating successful connections, not error messages.

## Comprehensive Verification Checklist

Work through this checklist systematically:

### Container Health
- [ ] All 4 services show "Up" status in `docker-compose ps`
- [ ] No services are in "Restarting" state
- [ ] No error messages in recent logs

### Database
- [ ] MySQL accepts connections from root user
- [ ] MySQL has `appuser` created
- [ ] `appdb` database exists
- [ ] API can connect to database (check logs)

### Cache
- [ ] Redis responds to PING with PONG
- [ ] Redis accepts password authentication
- [ ] API can connect to Redis (check logs)

### API Service
- [ ] `/health` endpoint returns healthy status
- [ ] `/` endpoint returns API message
- [ ] `/api` endpoint returns working message
- [ ] Logs show successful startup
- [ ] No connection errors in logs

### Frontend
- [ ] Returns HTML content on port 80
- [ ] Nginx configuration is loaded
- [ ] No errors in nginx logs

### End-to-End
- [ ] Frontend can proxy `/api` requests to backend
- [ ] Services can ping each other over Docker network
- [ ] No network connectivity errors

## Troubleshooting Common Issues

### Issue: Service Keeps Restarting

**Diagnosis:**
```bash
docker-compose logs <service-name>
```

**Common causes:**
- Missing environment variables
- Cannot connect to dependencies
- Application code errors
- Port already in use

### Issue: Database Connection Failed

**Diagnosis:**
```bash
docker-compose logs api | grep -i "mysql\|database"
docker-compose exec api ping -c 2 db
```

**Common causes:**
- DB_HOST doesn't match database service name
- DB_PORT doesn't match database container port
- Incorrect credentials or missing environment variables
- Database not ready yet (check db logs)

**Investigation:**
```bash
# Check what database service is defined
docker-compose config | grep -E "^  [a-z_-]+:" | grep -i "db\|mysql\|database"

# Verify API's database configuration
docker-compose config | grep -A 20 "^  api:" | grep -E "DB_"

# Check database service ports
docker-compose config | grep -A 15 "^  db:" | grep -E "ports|target|published"
```

### Issue: Redis Connection Failed

**Diagnosis:**
```bash
docker-compose logs api | grep -i "redis"
docker-compose exec cache redis-cli -a secretpass ping
```

**Common causes:**
- REDIS_HOST doesn't match cache service name
- REDIS_PASSWORD doesn't match Redis command password
- Redis not accepting connections

**Investigation:**
```bash
# Check what cache service is defined
docker-compose config | grep -E "^  [a-z_-]+:" | grep -i "cache\|redis"

# Verify API's Redis configuration
docker-compose config | grep -A 20 "^  api:" | grep -E "REDIS_"

# Check Redis password in command
docker-compose config | grep -A 10 "^  cache:" | grep -i "requirepass"
```

### Issue: Frontend Cannot Reach API

**Diagnosis:**
```bash
curl http://localhost/api
docker-compose logs frontend
cat nginx/default.conf
```

**Common causes:**
- Wrong service name in nginx proxy_pass
- Wrong port in nginx proxy_pass
- Services on different networks
- Nginx config not mounted correctly

### Issue: API Not Found Errors

**Diagnosis:**
```bash
docker-compose logs api
ls -la api/
```

**Common causes:**
- `api/index.js` missing
- Volume mount not configured
- npm dependencies not installed

## Performance and Health Monitoring

### Check Resource Usage
```bash
docker stats --no-stream
```

### View Detailed Service Info
```bash
docker-compose ps -a
docker inspect <container-name>
```

### Monitor Logs in Real-Time
```bash
docker-compose logs -f --tail=50
```

## Expected Outcome

After completing all tests successfully:

1. ✅ All 4 services are running (frontend, api, db, cache)
2. ✅ Services can communicate over the Docker network
3. ✅ Database accepts connections and has correct setup
4. ✅ Redis accepts authenticated connections
5. ✅ API responds to HTTP requests on port 3000
6. ✅ Frontend serves HTML content on port 80
7. ✅ Frontend successfully proxies `/api` requests to backend
8. ✅ No errors in service logs

## Real-World Implications

This troubleshooting exercise mirrors real production scenarios where:

- **Configuration drift** causes services to fail
- **Network issues** prevent inter-service communication
- **Missing environment variables** break integrations
- **Incorrect credentials** prevent database access
- **Port conflicts** prevent services from starting
- **Volume mount issues** prevent code from running

## Next Steps

Once all tests pass, proceed to the finish screen to review what you've learned.

**Congratulations!** You've successfully debugged and deployed a multi-service Docker Compose application.
