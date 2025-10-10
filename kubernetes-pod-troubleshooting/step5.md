# Step 5: Optimize Resources and Verify Stack

## Overview

In this final step, you'll optimize resource allocations, fix any remaining issues with the backend API, and perform end-to-end testing to ensure the complete application stack is working properly.

## Current Problems

At this stage, you should have:
- ✅ Frontend pod running (ConfigMap created in Step 4)
- ✅ PostgreSQL pod running (image fixed, PVC created, env vars added in Step 3)
- ✅ API pods running (application code fixed in Step 2)
- ✅ Redis pod running (was already working)
- ⚠️ Need to verify end-to-end functionality and test complete stack

## Tasks

### 1. Verify Current Status

First, check the status of all components:

```bash
# Check all pods
kubectl get pods -n webapp

# Check all services
kubectl get svc -n webapp

# Check all endpoints
kubectl get endpoints -n webapp

# Check ingress
kubectl get ingress -n webapp
```

### 2. Monitor Resource Usage

Check if pods have sufficient resources:

```bash
# Check node resources
kubectl top nodes

# Check pod resource usage
kubectl top pods -n webapp

# Check resource requests and limits
kubectl describe pods -n webapp | grep -A 5 -B 5 "Requests\|Limits"

# Check for resource-related events
kubectl get events -n webapp --field-selector reason=FailedScheduling
```

### 3. Test Complete Application Stack

Perform end-to-end testing of the complete application:

```bash
# Test all components are running (in webapp namespace)
kubectl get all -n webapp

# Get ingress NodePort
# Note: Ingress resource is in webapp namespace, but controller service is in ingress-nginx namespace
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
echo "Ingress NodePort: $INGRESS_PORT"

# Test from terminal
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/api/health
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/api/users

# OR use Killercoda Traffic Port Accessor (Top right of screen)
# Click "Traffic Port Accessor" and enter the NodePort number
# Then access in browser: http://<killercoda-url>/

# Test DNS resolution from Redis pod (using getent - works in alpine)
kubectl exec -it deployment/redis -n webapp -- getent hosts api-service
kubectl exec -it deployment/redis -n webapp -- getent hosts frontend-service

# Test actual database connection (from postgres pod)
kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user

# Test Redis connection (from redis pod)
kubectl exec -it deployment/redis -n webapp -- redis-cli ping

# Note: API is a mock service (nginx), it doesn't actually connect to postgres or redis
```

### 4. Analyze Pod Logs for Troubleshooting

**Important DevOps Skill**: Always check logs to verify applications are working correctly!

#### Check API Pod Logs:
```bash
# View API logs - look for startup messages
kubectl logs deployment/api -n webapp

# Expected healthy logs:
# - nginx startup messages
# - Port 3000 listening
# - No error messages

# If you see errors, investigate:
kubectl logs deployment/api -n webapp --previous  # Check previous container
kubectl logs deployment/api -n webapp --tail=50   # Last 50 lines
```

#### Check PostgreSQL Logs:
```bash
# View postgres logs
kubectl logs deployment/postgres -n webapp

# Look for:
# ✅ "database system is ready to accept connections"
# ✅ No authentication errors
# ❌ "FATAL: password authentication failed" (means env vars wrong)
# ❌ "out of memory" (means resource limits too low)

# Test database connection
kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user
# Expected: "accepting connections"
```

#### Check Redis Logs:
```bash
# View redis logs
kubectl logs deployment/redis -n webapp

# Look for:
# ✅ "Ready to accept connections"
# ✅ No memory errors
# ❌ "OOM" or "out of memory" (increase resources)

# Test Redis connection
kubectl exec -it deployment/redis -n webapp -- redis-cli ping
# Expected: "PONG"
```

#### Check Frontend Logs:
```bash
# View frontend logs
kubectl logs deployment/frontend -n webapp

# Look for nginx startup:
# ✅ "start worker process"
# ❌ Configuration errors

# Check nginx config is loaded
kubectl exec -it deployment/frontend -n webapp -- nginx -t
# Expected: "syntax is ok"
```

#### Check for Error Events:
```bash
# Get recent events (sorted by time)
kubectl get events -n webapp --sort-by='.lastTimestamp' | tail -20

# Look for:
# ❌ "Failed to pull image"
# ❌ "CrashLoopBackOff"
# ❌ "OOMKilled"
# ❌ "FailedScheduling"
```

### 5. Verify Database and Cache Connectivity

Test that database and cache are accessible:

```bash
# PostgreSQL connectivity test
echo "Testing PostgreSQL connection..."
kubectl exec -it deployment/postgres -n webapp -- psql -U webapp_user -d webapp -c "SELECT version();"

# Expected: PostgreSQL version info
# If error: Check POSTGRES_USER and POSTGRES_PASSWORD env vars

# Redis connectivity test
echo "Testing Redis connection..."
kubectl exec -it deployment/redis -n webapp -- redis-cli ping

# Expected: PONG
# If error: Check redis pod is Running

# Test Redis set/get
kubectl exec -it deployment/redis -n webapp -- redis-cli SET test "hello"
kubectl exec -it deployment/redis -n webapp -- redis-cli GET test
# Expected: "hello"
```

### 6. Final Health Check

```bash
# Check pod readiness and liveness
kubectl get pods -n webapp -o wide

# Verify all endpoints are healthy
kubectl get endpoints -n webapp

# Get ingress access details for testing
# Note: Ingress controller service is in ingress-nginx namespace (not webapp)
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
echo "Ingress NodePort: $INGRESS_PORT"

# Test load balancing (if multiple API replicas)
for i in {1..5}; do
  curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/api/health
  echo ""
done

# OR use Killercoda Traffic Port Accessor
# Click "Traffic Port Accessor" (top right) and enter the NodePort number
# Access in browser to test frontend and API endpoints
```

## Expected Results

After completing this step:
- All pods should be in `Running` state with `Ready` status
- Frontend should be accessible via ingress
- API should respond to health checks and requests
- Database and Redis should be accessible from API
- No error events in the namespace
- Resource usage should be within acceptable limits

## Final Verification

```bash
# Complete status check
echo "=== FINAL STATUS CHECK ==="
echo "Nodes:"
kubectl get nodes

echo -e "\nPods:"
kubectl get pods -n webapp

echo -e "\nServices:"
kubectl get svc -n webapp

echo -e "\nIngress:"
kubectl get ingress -n webapp

echo -e "\nPersistent Volumes:"
kubectl get pvc -n webapp

echo -e "\nApplication Test:"
# Note: Ingress controller service is in ingress-nginx namespace
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/api/health

echo -e "\n🎉 If all components are running and tests pass, congratulations!"
echo "You have successfully fixed the Kubernetes application!"
```

## Bonus: Production Readiness Improvements

For extra credit, consider implementing:
- Resource quotas for the namespace
- Network policies for security
- Secret management instead of hardcoded passwords
- Persistent volume backups
- Monitoring and alerting setup
- Rolling update strategies

**Congratulations!** You have successfully diagnosed and fixed a complex Kubernetes application with multiple failure points.