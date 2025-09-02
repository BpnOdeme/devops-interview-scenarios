# Step 4: Fix Health Checks

## Task

Ensure health checks are working properly for all registered services.

## Instructions

### 1. Check Current Health Status

```bash
# Check all service health
curl http://localhost:8500/v1/health/state/any | jq .

# Check specific service health
curl http://localhost:8500/v1/health/service/web | jq '.[].Checks'
curl http://localhost:8500/v1/health/service/api | jq '.[].Checks'

# Via CLI
docker exec consul consul members
```

### 2. Ensure Backend Services Are Running

Make sure the actual services are running:

```bash
# Check if web backend is running
docker ps | grep web-backend
curl http://localhost:8080/

# If not running, start it
docker run -d --name web-backend \
  -p 8080:80 \
  nginx:alpine

# Check if API backend is running
docker ps | grep api-backend
curl http://localhost:3000/

# If not running, start it
docker run -d --name api-backend \
  -p 3000:3000 \
  -e PORT=3000 \
  node:alpine sh -c "echo 'const http = require(\"http\"); http.createServer((req, res) => { res.writeHead(200); res.end(\"API Service OK\"); }).listen(3000);' | node"
```

### 3. Create Health Check Endpoints

For web service with custom health endpoint:

```bash
# Create health check page for nginx
docker exec web-backend sh -c 'echo "OK" > /usr/share/nginx/html/health'

# Test it
curl http://localhost:8080/health
```

### 4. Update Service Definitions with Better Health Checks

```bash
cat > /root/web-service-updated.json <<'EOF'
{
  "service": {
    "name": "web",
    "tags": ["primary", "v1", "nginx"],
    "port": 8080,
    "address": "host.docker.internal",
    "check": {
      "id": "web-health",
      "name": "Web Service Health Check",
      "http": "http://host.docker.internal:8080/",
      "method": "GET",
      "interval": "10s",
      "timeout": "5s",
      "deregister_critical_service_after": "30s"
    },
    "enable_tag_override": false,
    "weights": {
      "passing": 10,
      "warning": 1
    }
  }
}
EOF

cat > /root/api-service-updated.json <<'EOF'
{
  "service": {
    "name": "api",
    "tags": ["v1", "nodejs"],
    "port": 3000,
    "address": "host.docker.internal",
    "check": {
      "id": "api-health",
      "name": "API Service Health Check",
      "http": "http://host.docker.internal:3000/",
      "method": "GET",
      "interval": "10s",
      "timeout": "5s",
      "deregister_critical_service_after": "30s"
    }
  }
}
EOF
```

### 5. Re-register Services with Updated Health Checks

```bash
# Deregister old services
docker exec consul consul services deregister -id=web
docker exec consul consul services deregister -id=api

# Copy and register updated services
docker cp /root/web-service-updated.json consul:/tmp/
docker cp /root/api-service-updated.json consul:/tmp/

docker exec consul consul services register /tmp/web-service-updated.json
docker exec consul consul services register /tmp/api-service-updated.json
```

### 6. Monitor Health Check Status

```bash
# Watch health status
watch -n 2 'curl -s http://localhost:8500/v1/health/state/passing | jq ".[].Name"'

# Check in UI
echo "Open http://localhost:8500/ui/dc1/services"
```

### 7. Test Failure Detection

```bash
# Stop a service to see health check fail
docker stop web-backend

# Watch status change
curl http://localhost:8500/v1/health/service/web | jq '.[].Checks[].Status'

# Restart service
docker start web-backend

# Watch it recover
curl http://localhost:8500/v1/health/service/web | jq '.[].Checks[].Status'
```

## Health Check Types

### HTTP Check
```json
"check": {
  "http": "http://localhost:8080/health",
  "interval": "10s"
}
```

### TCP Check
```json
"check": {
  "tcp": "localhost:3306",
  "interval": "10s"
}
```

### Script Check (requires enable_script_checks)
```json
"check": {
  "args": ["/usr/local/bin/check.sh"],
  "interval": "10s"
}
```

### TTL Check
```json
"check": {
  "ttl": "30s"
}
```

## Expected Results

All services should show as "passing":
```json
{
  "Node": "consul-server",
  "CheckID": "web-health",
  "Name": "Web Service Health Check",
  "Status": "passing",
  "Output": "HTTP GET http://host.docker.internal:8080/: 200 OK"
}
```

## Checklist

- [ ] Backend services are running
- [ ] Health check URLs are correct
- [ ] Health checks are passing
- [ ] Timeout increased from 1s to 5s
- [ ] Services auto-deregister after critical
- [ ] Can see status in UI