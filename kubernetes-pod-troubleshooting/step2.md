# Step 2: Fix Service Communication and API Pods

## Overview

Now that you've identified the pod issues, it's time to fix the API pods and networking problems. In this step, you'll get the API pods running and ensure services can communicate properly.

## What This Step Verifies

The verification script (`verify-step2`) checks:
1. ✅ **2 API pods Running** (both must be in Running state)
2. ✅ **2 API pods Ready** (both must pass readiness checks)
3. ✅ **4 Services exist**: api-service, frontend-service, postgres-service, redis-cache
4. ✅ **api-service has endpoints** (must point to 2 API pod IPs)
5. ✅ **api-service selector is correct** (must be `app: api`)

**Note about endpoints:**
- Only `api-service` endpoints are checked in this step
- Frontend endpoints will be empty (pod needs ConfigMap - fixed in Step 4)
- Postgres endpoints may be empty if pod is still Pending (fixed in Step 3)
- Redis endpoints should already exist (pod is Running)

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

**IMPORTANT:** The verification script requires **exactly 4 services** to exist:

| Service Name | Port | TargetPort | Selector | Endpoints Required in Step 2? |
|--------------|------|------------|----------|-------------------------------|
| **api-service** | 3000 | 3000 | `app: api` | ✅ YES (must have 2 pod IPs) |
| **frontend-service** | 80 | 80 | `app: frontend` | ⚠️ NO (pod not ready yet) |
| **postgres-service** | 5432 | 5432 | `app: postgres` | ⚠️ MAYBE (depends if Step 3 done) |
| **redis-cache** | 6379 | 6379 | `app: redis` | ✅ YES (already running) |

```bash
# Check which services exist
kubectl get svc -n webapp

# Check which services have endpoints
kubectl get endpoints -n webapp
```

**If services are missing, create them with:**
- Correct `selector` matching pod labels (check with `kubectl get pods --show-labels -n webapp`)
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
- `metadata.name`: Service name (must match table above)
- `spec.selector`: Must match pod labels exactly
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

## Expected Results - What Must Pass to Complete Step 2

**To pass verification, you must have:**

### ✅ Must Be Fixed:
1. **2 API pods Running** - Check with: `kubectl get pods -n webapp -l app=api`
2. **2 API pods Ready (1/1)** - Both containers must pass readiness checks
3. **All 4 services exist:**
   - `api-service` ✅
   - `frontend-service` ✅
   - `postgres-service` ✅
   - `redis-cache` ✅ (already exists)
4. **api-service has endpoints** - Must show 2 pod IPs: `kubectl get endpoints api-service -n webapp`
5. **api-service selector is `app: api`** - Check with: `kubectl get svc api-service -n webapp -o yaml`

### ⚠️ Expected to Still Be Broken (Will Fix Later):
- **Frontend pod**: Still ContainerCreating (missing nginx-config ConfigMap - fixed in Step 4)
- **Postgres pod**: May be Pending (missing PVC - fixed in Step 3)
- **frontend-service endpoints**: Will be empty (pod not ready)
- **postgres-service endpoints**: May be empty (pod may not be ready)

### 📊 Service Endpoints Status Expected:
```bash
kubectl get endpoints -n webapp

# Expected output after Step 2:
NAME                 ENDPOINTS                           AGE
api-service          10.244.0.x:3000,10.244.0.y:3000    Xm  ✅ HAS ENDPOINTS
frontend-service     <none>                             Xm  ⚠️ EMPTY (OK for now)
postgres-service     <none>                             Xm  ⚠️ EMPTY (OK for now)
redis-cache          10.244.0.z:6379                    Xm  ✅ HAS ENDPOINTS
```

**Remember:** Only `api-service` endpoints are verified in Step 2!

## Verification Commands

Run these commands to check if you're ready to pass Step 2:

```bash
# 1. Check API pods (must be 2 Running, 2 Ready)
kubectl get pods -n webapp -l app=api

# 2. Check all services exist (must be exactly 4)
kubectl get svc -n webapp

# 3. Check api-service has endpoints (must show 2 pod IPs)
kubectl get endpoints api-service -n webapp

# 4. Check api-service selector (must be app=api)
kubectl get svc api-service -n webapp -o jsonpath='{.spec.selector}'; echo

# 5. View all endpoints status
kubectl get endpoints -n webapp

# Test DNS resolution from API pod (using getent)
kubectl exec -it deployment/api -n webapp -- getent hosts postgres-service

# Check API pod logs
kubectl logs deployment/api -n webapp
```

## Quick Troubleshooting Checklist

Before running the verification script, check:

- [ ] Did you apply the API ConfigMap? (`kubectl apply -f /root/k8s-app/configmaps/api-config.yaml`)
- [ ] Are 2 API pods Running? (`kubectl get pods -n webapp -l app=api`)
- [ ] Are 2 API pods Ready (1/1)?
- [ ] Do you have exactly 4 services? (`kubectl get svc -n webapp | wc -l` should be 5 including header)
- [ ] Does api-service exist? (`kubectl get svc api-service -n webapp`)
- [ ] Does frontend-service exist? (`kubectl get svc frontend-service -n webapp`)
- [ ] Does postgres-service exist? (`kubectl get svc postgres-service -n webapp`)
- [ ] Does redis-cache service exist? (`kubectl get svc redis-cache -n webapp`)
- [ ] Does api-service have 2 endpoints? (`kubectl get endpoints api-service -n webapp`)
- [ ] Is api-service selector `app: api`? (`kubectl get svc api-service -n webapp -o yaml | grep -A2 selector`)

**Next**: Once services can communicate properly, proceed to **Step 3** to fix storage and database issues.
