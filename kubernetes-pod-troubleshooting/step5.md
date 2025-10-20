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

### 2. Fix API Container Port and Resource Limits

**Problem Investigation:**
The API pods are running but health checks might be failing. Investigate the configuration:

```bash
# Check API deployment configuration
kubectl get deployment api -n webapp -o yaml | grep -A 10 "containers:"

# Check what port the API is configured to use
kubectl get configmap api-config -n webapp -o yaml

# Check current resource limits
kubectl get deployment api -n webapp -o jsonpath='{.spec.template.spec.containers[0].resources}'
```

**Issues to Fix:**

#### Issue 1: Container Port Mismatch
The API deployment has `containerPort: 80` but the ConfigMap configures nginx to listen on port **3000**.

**Fix the container port:**
```bash
# Option 1: Edit deployment directly
kubectl edit deployment api -n webapp
# Find "containerPort: 80" and change to "containerPort: 3000"

# Option 2: Use kubectl patch
kubectl patch deployment api -n webapp --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/ports/0/containerPort", "value":3000}]'
```

#### Issue 2: Memory Limits Too Low
The API deployment has only `64Mi` memory, which is too low for a web service.

**Increase memory limits:**
```bash
# Increase memory to 128Mi
kubectl set resources deployment api -n webapp \
  --limits=memory=128Mi,cpu=200m \
  --requests=memory=64Mi,cpu=100m

# Verify the change
kubectl get deployment api -n webapp -o jsonpath='{.spec.template.spec.containers[0].resources}'
```

**Wait for pods to restart:**
```bash
# Watch pod restart with new configuration
kubectl rollout status deployment/api -n webapp

# Verify new pods are running
kubectl get pods -n webapp -l app=api
```

### 3. Monitor Resource Usage

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

### 4. Test Complete Application Stack

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

#### Troubleshooting: If Ingress Returns 404

If curl to ingress returns 404 even though all pods are Running and services have endpoints:

**Step 1: Verify Service Access Works**
```bash
# Test API directly via service (should work)
kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n webapp -- curl -s http://api-service:3000/health

# Test API from within API pod (should work)
kubectl exec -it deployment/api -n webapp -- curl -s localhost:3000/health

# If both work but ingress returns 404, the issue is with ingress configuration
```

**Step 2: Check Ingress Controller Logs**
```bash
# Check if ingress controller is processing your ingress
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=30

# Look for warnings like:
# - "ignoring ingress"
# - "IngressClass"
# - "does not contain a valid IngressClass"
```

**Step 3: Investigate Ingress Configuration**
```bash
# Check ingress resource details
kubectl get ingress webapp-ingress -n webapp -o yaml

# Check if ingressClassName is set
kubectl get ingress webapp-ingress -n webapp -o jsonpath='{.spec.ingressClassName}'

# If empty or missing, that's your problem!
```

**Step 4: Fix Missing IngressClass**

The ingress controller requires `ingressClassName` to be specified. Without it, the controller ignores the ingress resource completely.

```bash

kubectl edit ingress webapp-ingress -n webapp
# Add this line under spec:
#   ingressClassName: nginx

# Verify the fix
kubectl get ingress webapp-ingress -n webapp -o yaml | grep ingressClassName
```

**Step 5: Test Again**
```bash
# Wait a moment for ingress controller to reload configuration
sleep 5

# Test the API endpoint
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/api/health

# Should now return: {"status":"healthy"}
```

**Why This Happens:**
- Kubernetes v1.18+ supports multiple ingress controllers
- `ingressClassName` specifies which controller should handle the ingress
- Without it, ingress-nginx controller v1.8.1+ ignores the ingress resource
- Always check controller logs when ingress doesn't work!

### 5. Analyze Pod Logs for Troubleshooting

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

### 6. Verify Database and Cache Connectivity

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

### 7. Final Health Check

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