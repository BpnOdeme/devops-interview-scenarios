# Step 2: Fix Service Communication and API Pods

## Overview

Now that you've identified the pod issues, it's time to fix the API pods and networking problems. In this step, you'll get the API pods running and ensure services can communicate properly.

## Current Problems

Multiple issues need to be resolved:
- **API pods**: Not running properly - investigate why
- **Service endpoints**: Some services have no endpoints
- **Service communication**: DNS may work but endpoints are missing

## Tasks

### 1. Investigate API Pod Issues

The API pods are not running. Find out why:

```bash
# Check API pod status
kubectl get pods -n webapp -l app=api

# Get detailed information
kubectl describe pod -l app=api -n webapp

# Check deployment configuration
kubectl get deployment api -n webapp -o yaml

# Look for issues in Events section
kubectl get events -n webapp --field-selector involvedObject.name=api
```

**Common investigation steps:**
- Is there a missing ConfigMap?
- Are there volume mount errors?
- Check what ConfigMaps exist: `kubectl get configmaps -n webapp`
- Check if there are prepared files in `/root/k8s-app/configmaps/`

**Hint:** Look in `/root/k8s-app/configmaps/` for solution files.

### 2. Fix API Pods

After identifying the issue, fix it:

```bash
# List available solution files
ls -la /root/k8s-app/configmaps/

# Apply the necessary ConfigMap
kubectl apply -f /root/k8s-app/configmaps/api-config.yaml

# Watch pods start
kubectl get pods -n webapp -l app=api -w
```

### 3. Investigate Service Endpoints

Check why some services have no endpoints:

```bash
# List all services and endpoints
kubectl get svc,endpoints -n webapp

# Check which services have endpoints
kubectl get endpoints -n webapp

# Investigate services without endpoints
kubectl describe svc api-service -n webapp

# Compare service selector with pod labels
kubectl get pods -n webapp --show-labels
```

**Key question:** Do the service selectors match the pod labels?

### 4. Fix Service Selectors

If you find a mismatch between service selectors and pod labels, fix it:

```bash
# Option 1: Edit the service interactively
kubectl edit svc <service-name> -n webapp
# Update the selector to match pod labels

# Option 2: Use patch command
kubectl patch svc <service-name> -n webapp -p '{"spec":{"selector":{"app":"<correct-label>"}}}'

# Verify endpoints are created after fix
kubectl get endpoints <service-name> -n webapp
```

**Hint:** Compare service selector with actual pod labels using `kubectl get pods --show-labels`

### 5. Verify All Required Services Exist

The application architecture requires these services:

```bash
# List current services
kubectl get svc -n webapp

# Required services and their ports:
# - API service: exposes port 3000 (for API pods)
# - Frontend service: exposes port 80 (for nginx frontend)
# - Database service: exposes port 5432 (for PostgreSQL)
# - Redis cache: already exists ✅
```

**If services are missing, create them with:**
- Correct `selector` matching pod labels
- Appropriate `port` and `targetPort`
- `type: ClusterIP` for internal communication

**Example service creation pattern:**
```bash
kubectl create service clusterip <service-name> \
  --tcp=<port>:<targetPort> \
  -n webapp

# Then edit to add correct selector
kubectl edit svc <service-name> -n webapp
```

**Or use kubectl apply with YAML** - define Service with:
- `metadata.name`: Service name
- `spec.selector`: Must match pod labels
- `spec.ports`: Port mapping
- `spec.type`: ClusterIP

### 6. Verify Service Communication

Test that services can resolve each other:

```bash
# Test DNS resolution from API pod
kubectl exec -it deployment/api -n webapp -- getent hosts postgres-service
kubectl exec -it deployment/api -n webapp -- getent hosts redis-cache

# Check all endpoints
kubectl get endpoints -n webapp

# Verify API service has endpoints
kubectl describe endpoints api-service -n webapp
```

## Expected Results

After completing this step:
- ✅ API pods should be Running and healthy (2/2 ready)
- ✅ API service should have valid endpoints (2 pod IPs)
- ✅ postgres-service should have valid endpoints (1 pod IP from the Running postgres pod)
- ✅ redis-cache should have valid endpoints (1 pod IP)
- ⚠️ **frontend-service will have NO endpoints** (pod still ContainerCreating - ConfigMap created in Step 4)
- ✅ DNS resolution should work between services
- ✅ Service selectors should match pod labels
- ⚠️ Frontend still ContainerCreating (will fix in Step 4)
- ⚠️ Postgres may be Pending if PVC not created (will fix in Step 3)

## Verification Commands

```bash
# Verify services have correct selectors and endpoints
kubectl get svc,endpoints -n webapp

# Test DNS resolution from API pod (using getent)
kubectl exec -it deployment/api -n webapp -- getent hosts postgres-service

# Check API pod logs
kubectl logs deployment/api -n webapp
```

**Next**: Once services can communicate properly, proceed to fix storage and database issues.
