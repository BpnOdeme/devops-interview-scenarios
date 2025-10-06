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

### 4. Create Database Service

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

### 5. Fix Backend Database Connection

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

### 6. Verify Service Communication

Test that services can resolve DNS names correctly and have proper endpoints:

```bash
# Check if services have endpoints
kubectl get endpoints -n webapp

# Verify API service now has endpoints
kubectl describe svc api-service -n webapp

# Test DNS resolution from a running pod
kubectl exec -it deployment/redis -n webapp -- nslookup api-service.webapp.svc.cluster.local

# Verify postgres service (once pod is running)
kubectl get endpoints postgres-service -n webapp
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