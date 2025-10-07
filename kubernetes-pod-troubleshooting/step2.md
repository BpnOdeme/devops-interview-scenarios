# Step 2: Fix Service Communication and API Pods

## Overview

Now that you've identified the pod issues, it's time to fix the API pods and networking problems. In this step, you'll get the API pods running and ensure services can communicate properly.

## Current Problems

Multiple issues need to be resolved:
- **API pods**: CrashLoopBackOff - need working application code
- **Service selectors**: Don't match pod labels
- **Missing services**: Frontend and Postgres services don't exist
- **Endpoints**: Not being created properly due to wrong selectors

## Tasks

### 1. Fix API Pods First

The API pods are in ContainerCreating or CrashLoopBackOff state. Let's investigate:

```bash
# Check API pod status
kubectl get pods -n webapp -l app=api

# Describe the pod to see what's wrong
kubectl describe pod -l app=api -n webapp

# You'll see: MountVolume.SetUp failed - configmap "api-config-missing" not found
```

The API deployment references a missing ConfigMap. Let's check the deployment and fix it:

```bash
# Check current deployment
kubectl get deployment api -n webapp -o yaml | grep -A 5 "volumes:"

# Look at the broken deployment file
cat /root/k8s-app/deployments/api-deployment.yaml

# Compare with the solution version
cat /root/k8s-app/deployments/api-deployment-SOLUTION.yaml

# Or use diff to see differences
diff /root/k8s-app/deployments/api-deployment.yaml /root/k8s-app/deployments/api-deployment-SOLUTION.yaml
```

**Issues found:**
1. ConfigMap `api-config-missing` doesn't exist
2. Container port is wrong: `80` → should be `3000`
3. Resources too low: need more memory
4. Image should be nginx:alpine (not nginx:1.21)

**Fix Option 1 - Create the missing ConfigMap (simplest):**
```bash
# Create the missing ConfigMap - this will make pods start
kubectl apply -f /root/k8s-app/configmaps/api-config.yaml

# Verify pods are starting
kubectl get pods -n webapp -l app=api -w
```

**Fix Option 2 - Apply the complete solution:**
```bash
# Apply both ConfigMap and fixed deployment
kubectl apply -f /root/k8s-app/configmaps/api-config.yaml
kubectl apply -f /root/k8s-app/deployments/api-deployment-SOLUTION.yaml

# Wait for rollout
kubectl rollout status deployment/api -n webapp
```

**Note:** Option 1 is enough to get pods running for Step 2. The deployment still has wrong port (80 instead of 3000) and old image, but pods will be Running and Ready, which is what Step 2 requires.

### 2. Check Service Configuration

Now examine the current services and their endpoints:

```bash
# List all services in the webapp namespace
kubectl get svc -n webapp

# Check endpoints for each service
kubectl get endpoints -n webapp

# Describe services to see selectors
kubectl describe svc -n webapp
```

### 3. Fix Service Selectors

The API service has an incorrect selector that doesn't match the pod labels. Let's check and fix it:

```bash
# Check current service configuration
kubectl describe svc api-service -n webapp

# Check what labels the API pods actually have
kubectl get pods -n webapp -l app=api --show-labels
```

**Issue**: The selector is `app: backend` but should be `app: api`

**Fix Option 1 - Edit the service directly:**
```bash
kubectl edit svc api-service -n webapp
# Change selector from 'app: backend' to 'app: api'
```

**Fix Option 2 - Apply corrected YAML:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: webapp
spec:
  selector:
    app: api  # Fixed selector
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF
```

### 4. Create Missing Services

Some services are missing entirely. Create the frontend service:

```bash
# Create frontend service
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: webapp
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

### 5. Create Database Service

The backend deployment references a database service that doesn't exist yet. Let's create it:

```bash
# Check if postgres service exists
kubectl get svc -n webapp | grep postgres

# Create the postgres service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: webapp
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
```

### 6. Fix Backend Database Connection

The API deployment has the wrong database service name in its environment variables:

```bash
# Check current DATABASE_URL
kubectl get deployment api -n webapp -o yaml | grep DATABASE_URL
```

**Issue**: DATABASE_URL points to `postgres-wrong:5432`
**Fix**: Update it to `postgres-service:5432`

```bash
kubectl set env deployment/api -n webapp DATABASE_URL="postgresql://user:pass@postgres-service:5432/webapp"
```

### 7. Verify Service Communication

Test that services can resolve DNS names correctly and have proper endpoints:

```bash
# Check if services have endpoints
kubectl get endpoints -n webapp

# Verify API service now has endpoints
kubectl describe svc api-service -n webapp

# Test DNS resolution from a running pod (using getent - available in alpine)
kubectl exec -it deployment/redis -n webapp -- getent hosts api-service

# Verify postgres service (once pod is running)
kubectl get endpoints postgres-service -n webapp
```

## Expected Results

After completing this step:
- ✅ API pods should be Running and healthy (2/2 ready)
- ✅ All services should have valid endpoints
- ✅ DNS resolution should work between services
- ✅ Service selectors should match pod labels
- ⚠️ Frontend still ContainerCreating (will fix in Step 4)
- ⚠️ Postgres still Pending (will fix in Step 3)

## Verification Commands

```bash
# Verify services have correct selectors and endpoints
kubectl get svc,endpoints -n webapp

# Test DNS resolution from API pod (using getent)
kubectl exec -it deployment/api -n webapp -- getent hosts postgres-service
```

**Next**: Once services can communicate properly, proceed to fix storage and database issues.