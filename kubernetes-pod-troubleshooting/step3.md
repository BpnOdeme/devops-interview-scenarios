# Step 3: Fix Storage and Database Issues

## Overview

In this step, you'll resolve storage problems and get the PostgreSQL database running properly. This involves fixing PersistentVolumeClaim issues and database configuration.

## Current Problems

The database pod has multiple issues:
- **Postgres pod**: May be Pending or ImagePullBackOff - investigate why
- **Storage**: PVC might not be bound
- **Database configuration**: Missing environment variables

## Tasks

### 1. Investigate Postgres Pod Status

Check why the postgres pod isn't running:

```bash
# Check postgres pod status
kubectl get pods -n webapp -l app=postgres

# Get detailed information
kubectl describe pod -l app=postgres -n webapp

# Look for common issues:
# - Image pull errors
# - PVC binding issues
# - Missing environment variables
```

### 2. Fix Image Issues

If you see ImagePullBackOff:

```bash
# Check current image
kubectl get deployment postgres -n webapp -o jsonpath='{.spec.template.spec.containers[0].image}'

# Common postgres images:
# - postgres:13
# - postgres:14
# - postgres:15

# Fix the deployment
kubectl set image deployment/postgres postgres=postgres:15 -n webapp

# Or edit directly
kubectl edit deployment postgres -n webapp
```

### 3. Investigate Storage Issues

Check PersistentVolumeClaim status:

```bash
# List PVCs
kubectl get pvc -n webapp

# Describe PVC to see why it's not binding
kubectl describe pvc postgres-pvc -n webapp

# Check available storage classes
kubectl get storageclass

# Common issues:
# - Wrong storage class name
# - Storage class doesn't exist
# - Insufficient resources
```

**Fix PVC if needed:**

```bash
# Check current PVC configuration
kubectl get pvc postgres-pvc -n webapp -o yaml

# If wrong storage class, delete and recreate
kubectl delete pvc postgres-pvc -n webapp

# Create new PVC with correct storage class
# Use kubectl apply with a PVC manifest that includes:
# - accessModes: ReadWriteOnce
# - storageClassName: <available-storage-class>
# - storage: 1Gi
```

**Hints:**
- Check available storage classes: `kubectl get storageclass`
- Common storage classes: `local-path`, `standard`, `hostpath`
- PVC must be in same namespace as the pod

### 4. Fix Postgres Deployment Configuration

Check the deployment for issues:

```bash
# Get current deployment configuration
kubectl get deployment postgres -n webapp -o yaml

# Check environment variables
kubectl get deployment postgres -n webapp -o jsonpath='{.spec.template.spec.containers[0].env}'

# Check PVC reference
kubectl get deployment postgres -n webapp -o yaml | grep -A 5 "volumes:"
```

**Common fixes needed:**

1. **Add missing environment variables:**
```bash
# PostgreSQL requires these environment variables:
# - POSTGRES_USER: Database user
# - POSTGRES_PASSWORD: Database password
# - POSTGRES_DB: Database name

kubectl set env deployment/postgres -n webapp \
  POSTGRES_USER=<user> \
  POSTGRES_PASSWORD=<password> \
  POSTGRES_DB=<database-name>
```

2. **Fix PVC name if wrong:**
```bash
kubectl edit deployment postgres -n webapp
# In volumes section, update persistentVolumeClaim.claimName
# Must match the actual PVC name
```

3. **Increase resource limits if too low:**
```bash
# PostgreSQL typically needs:
# - Memory: at least 128Mi-256Mi
# - CPU: 250m-500m

kubectl set resources deployment/postgres -n webapp \
  --limits=memory=<limit>,cpu=<limit> \
  --requests=memory=<request>,cpu=<request>
```

### 5. Verify Database is Running

After fixes, verify the database:

```bash
# Check pod status
kubectl get pods -n webapp -l app=postgres

# Check pod logs
kubectl logs deployment/postgres -n webapp

# Look for:
# ✅ "database system is ready to accept connections"
# ❌ "FATAL: password authentication failed"

# Test database connection
kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user

# Test actual connection
kubectl exec -it deployment/postgres -n webapp -- psql -U webapp_user -d webapp -c "SELECT version();"
```

### 6. Verify PVC is Bound

Check that the PVC is properly bound:

```bash
# Check PVC status
kubectl get pvc -n webapp

# Verify it's bound to a PV
kubectl describe pvc postgres-pvc -n webapp

# Check the actual PV
kubectl get pv
```

## Expected Results

After completing this step:
- ✅ Postgres pod should be Running (1/1 ready)
- ✅ PVC should be Bound status
- ✅ Database should accept connections
- ✅ postgres-service should have valid endpoint
- ✅ Pod logs show "ready to accept connections"
- ⚠️ Frontend still ContainerCreating (will fix in Step 4)

## Verification Commands

```bash
# Complete status check
kubectl get pods,pvc -n webapp

# Check postgres service endpoint
kubectl get endpoints postgres-service -n webapp

# Test database connection
kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user

# Check pod logs
kubectl logs deployment/postgres -n webapp | tail -20
```

**Next**: Proceed to Step 4 to configure ingress and enable external access.
