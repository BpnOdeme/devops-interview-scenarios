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
# Test all components are running
kubectl get all -n webapp

# Test frontend access
curl -H "Host: webapp.local" http://$(minikube ip)/

# Test API directly
curl -H "Host: webapp.local" http://$(minikube ip)/api/health

# Test API endpoints
curl -H "Host: webapp.local" http://$(minikube ip)/api/users

# Test database connectivity from API pod
kubectl exec -it deployment/api -n webapp -- wget -qO- http://postgres-service:5432 || echo "Database connection test"

# Test Redis connectivity
kubectl exec -it deployment/api -n webapp -- wget -qO- http://redis-cache:6379 || echo "Redis connection test"
```

### 4. Verify Pod Health and Logs

Verify all services are working properly:

```bash
# Check all pod logs
kubectl logs deployment/frontend -n webapp
kubectl logs deployment/api -n webapp
kubectl logs deployment/postgres -n webapp
kubectl logs deployment/redis -n webapp

# Check for any error events
kubectl get events -n webapp --sort-by='.lastTimestamp' | tail -20
```

### 5. Final Health Check

```bash
# Check pod readiness and liveness
kubectl get pods -n webapp -o wide

# Verify all endpoints are healthy
kubectl get endpoints -n webapp

# Test load balancing (if multiple API replicas)
for i in {1..5}; do
  curl -H "Host: webapp.local" http://$(minikube ip)/api/health
  echo ""
done
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
curl -H "Host: webapp.local" http://$(minikube ip)/api/health

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