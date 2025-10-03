# Step 5: Optimize Resources and Verify Stack

## Overview

In this final step, you'll optimize resource allocations, fix any remaining issues with the backend API, and perform end-to-end testing to ensure the complete application stack is working properly.

## Current Problems

- Backend API deployment still has issues with application startup
- Resource limits may be too restrictive
- Need to verify complete application functionality
- Missing health checks and monitoring

## Tasks

### 1. Fix Backend API Configuration

The backend API pod needs proper port configuration and resource allocation:

Fix the API deployment configuration:

```bash
# Edit the API deployment
kubectl edit deployment api -n webapp

# Fix these issues:
# 1. Change containerPort from 80 to 3000
# 2. Increase memory limits (128Mi minimum)
# 3. Fix service references in environment variables
```

### 2. Alternative: Use File-Based Editing

Edit the deployment file directly:

```bash
# Navigate to deployments directory
cd /root/k8s-app/deployments

# Edit API deployment file
vim api-deployment.yaml

# Update the following:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      initContainers:
      - name: install-deps
        image: node:16-alpine
        command: ["/bin/sh"]
        args: ["-c", "cd /app && npm install"]
        volumeMounts:
        - name: api-code
          mountPath: /app
        - name: node-modules
          mountPath: /app/node_modules
      containers:
      - name: api
        image: node:16-alpine
        command: ["/bin/sh"]
        args: ["-c", "cd /app && npm start"]
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          value: "postgresql://webapp_user:webapp_password@postgres-service:5432/webapp"
        - name: REDIS_URL
          value: "redis://redis-cache:6379"
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        volumeMounts:
        - name: api-code
          mountPath: /app
        - name: node-modules
          mountPath: /app/node_modules
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: api-code
        configMap:
          name: api-code
      - name: node-modules
        emptyDir: {}
EOF
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

### 4. Add Horizontal Pod Autoscaler (Optional)

For production readiness, add autoscaling:

```bash
# Enable metrics server (if not already enabled)
minikube addons enable metrics-server

# Create HPA for API
kubectl autoscale deployment api --cpu-percent=70 --min=2 --max=5 -n webapp

# Check HPA status
kubectl get hpa -n webapp
```

### 5. Comprehensive Testing

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

### 6. Check Application Logs

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

### 7. Performance and Health Verification

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