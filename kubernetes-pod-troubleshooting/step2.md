# Step 2: Fix Service Communication

## Overview

Now that you've identified the pod issues, it's time to fix the networking and service communication problems. Services in Kubernetes need proper selectors and endpoints to route traffic correctly.

## Current Problems

The services are misconfigured and cannot route traffic to the correct pods:
- Service selectors don't match pod labels
- Wrong service names are referenced in configurations
- Endpoints are not being created properly

## Tasks

### 1. Check Service Configuration

First, examine the current services and their endpoints:

```bash
# List all services in the webapp namespace
kubectl get svc -n webapp

# Check endpoints for each service
kubectl get endpoints -n webapp

# Describe services to see selectors
kubectl describe svc -n webapp
```

### 2. Fix Service Selectors

The API service has an incorrect selector. Edit the service:

```bash
kubectl edit svc api-service -n webapp
```

**Issue**: The selector is `app: backend` but should be `app: api`
**Fix**: Change the selector to match the pod labels

### 3. Create Missing Services

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

### 4. Fix Database Service Reference

The backend deployment references the wrong database service name. Edit the deployment:

```bash
kubectl edit deployment api -n webapp
```

**Issue**: DATABASE_URL points to `postgres-wrong:5432`
**Fix**: Change it to `postgres-service:5432`

First, create the correct database service:

```bash
cat << 'EOF' | kubectl apply -f -
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

### 5. Verify Service Communication

Test that services can resolve DNS names correctly:

```bash
# Test DNS resolution from a test pod
kubectl run test-pod --image=busybox --rm -it --restart=Never -n webapp -- nslookup postgres-service.webapp.svc.cluster.local

# Check if services have endpoints
kubectl get endpoints -n webapp
```

## Expected Results

After fixing the service issues:
- All services should have valid endpoints
- DNS resolution should work between services
- Pod-to-pod communication should be functional

## Verification Commands

```bash
# Verify services have correct selectors and endpoints
kubectl get svc,endpoints -n webapp

# Test connectivity between services
kubectl exec -it <api-pod-name> -n webapp -- wget -qO- http://postgres-service:5432
```

**Next**: Once services can communicate properly, proceed to fix storage and database issues.