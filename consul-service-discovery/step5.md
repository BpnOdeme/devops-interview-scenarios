# Step 5: Test Service Discovery

## Task

Verify that service discovery is working correctly through DNS, API, and the UI.

## Instructions

### 1. Test DNS-Based Service Discovery

```bash
# Query services via DNS
dig @127.0.0.1 -p 8600 web.service.consul
dig @127.0.0.1 -p 8600 api.service.consul

# Get SRV records (includes port information)
dig @127.0.0.1 -p 8600 web.service.consul SRV
dig @127.0.0.1 -p 8600 api.service.consul SRV

# Query all services
dig @127.0.0.1 -p 8600 consul.service.consul

# Get service with specific tag
dig @127.0.0.1 -p 8600 primary.web.service.consul
```

### 2. Test HTTP API Service Discovery

```bash
# List all services
curl http://localhost:8500/v1/catalog/services | jq .

# Get service details
curl http://localhost:8500/v1/catalog/service/web | jq .
curl http://localhost:8500/v1/catalog/service/api | jq .

# Get healthy service instances only
curl http://localhost:8500/v1/health/service/web?passing=true | jq '.[] | {Service: .Service.Service, Address: .Service.Address, Port: .Service.Port, Status: .Checks[].Status}'

# Get service configuration
curl http://localhost:8500/v1/agent/services | jq .
```

### 3. Test Service Discovery Integration

Create a simple service discovery client:

```bash
cat > /root/test-discovery.sh <<'EOF'
#!/bin/bash

echo "=== Service Discovery Test ==="

# Discover web service
echo -e "\n1. Discovering web service via DNS:"
WEB_IP=$(dig +short @127.0.0.1 -p 8600 web.service.consul | head -1)
echo "   Web service IP: $WEB_IP"

# Discover API service
echo -e "\n2. Discovering API service via DNS:"
API_IP=$(dig +short @127.0.0.1 -p 8600 api.service.consul | head -1)
echo "   API service IP: $API_IP"

# Get service details via API
echo -e "\n3. Getting service details via HTTP API:"
curl -s http://localhost:8500/v1/catalog/service/web | jq -r '.[] | "   Web: \(.ServiceAddress):\(.ServicePort)"'
curl -s http://localhost:8500/v1/catalog/service/api | jq -r '.[] | "   API: \(.ServiceAddress):\(.ServicePort)"'

# Test actual service connectivity
echo -e "\n4. Testing service connectivity:"
curl -s -o /dev/null -w "   Web service: %{http_code}\n" http://localhost:8080/
curl -s -o /dev/null -w "   API service: %{http_code}\n" http://localhost:3000/
EOF

chmod +x /root/test-discovery.sh
/root/test-discovery.sh
```

### 4. Test Load Balancing

If multiple instances of a service exist:

```bash
# Register additional web instance
cat > /root/web-service-2.json <<'EOF'
{
  "service": {
    "id": "web-2",
    "name": "web",
    "tags": ["secondary", "v1"],
    "port": 8081,
    "address": "localhost",
    "check": {
      "http": "http://localhost:8081/",
      "interval": "10s"
    }
  }
}
EOF

# Multiple DNS queries should show round-robin
for i in {1..5}; do
  dig +short @127.0.0.1 -p 8600 web.service.consul
done
```

### 5. Test Service Mesh Features (Optional)

```bash
# Check Connect-enabled services
curl http://localhost:8500/v1/agent/services | jq '.[] | select(.Connect != null)'

# Get service intentions
curl http://localhost:8500/v1/connect/intentions

# Get CA roots
curl http://localhost:8500/v1/connect/ca/roots
```

### 6. Use Consul Template (Bonus)

Create a template that updates based on service discovery:

```bash
cat > /root/services.tpl <<'EOF'
Services:
{{range services}}
- {{.Name}} ({{len .Tags}} tags)
  {{range service .Name}}
  * {{.Address}}:{{.Port}}{{end}}
{{end}}
EOF

# Would use: consul-template -template="/root/services.tpl:/root/services.txt"
```

## Consul UI Verification

1. Open http://localhost:8500/ui
2. Navigate to Services tab
3. Verify all services are listed
4. Check health status indicators
5. Click on each service for details

## Expected Results

### DNS Query Result
```
;; ANSWER SECTION:
web.service.consul.     0       IN      A       172.17.0.1
```

### API Query Result
```json
{
  "web": ["primary", "v1", "nginx"],
  "api": ["v1", "nodejs"],
  "consul": []
}
```

### Health Check Result
```json
{
  "Service": "web",
  "Address": "localhost",
  "Port": 8080,
  "Status": "passing"
}
```

## Final Validation Checklist

- [ ] DNS queries return service IPs
- [ ] HTTP API returns service information
- [ ] Health checks are passing
- [ ] UI shows all services as healthy
- [ ] Service discovery script works
- [ ] Can discover services programmatically

## Production Best Practices

1. **Use Prepared Queries** for advanced filtering
2. **Implement Health Check Grace Periods** for new services
3. **Use Service Mesh** for secure service-to-service communication
4. **Configure Watches** for real-time updates
5. **Set up ACLs** in production environments
6. **Use Anti-Entropy** to sync state
7. **Implement Circuit Breakers** based on health status

Congratulations! Consul service discovery is now working correctly!