# Step 4: Configure Ingress and External Access

## Overview

In this step, you'll fix the ingress configuration to enable external access to the application. The current ingress has wrong service references and missing configurations.

## Current Problems

Based on the current setup:
- Frontend deployment is **ContainerCreating** - investigate why
- Frontend service may need verification
- Ingress configuration needs to be created
- Ingress controller should already be deployed (Nginx Ingress Controller)

## Tasks

### 1. Check Ingress Controller Status

First, verify the ingress controller is running:

```bash
# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 2. Investigate Frontend Pod Issue

The frontend pod is not starting. Investigate why:

```bash
# Check frontend pod status
kubectl get pods -n webapp -l app=frontend

# Get detailed information about the pod
kubectl describe pod -l app=frontend -n webapp

# Look for error messages in the Events section
# Common issues:
# - Missing ConfigMap
# - Image pull errors
# - Volume mount failures
```

**Hints:**
- Check what ConfigMap the deployment is trying to mount
- Verify if that ConfigMap exists: `kubectl get configmaps -n webapp`
- Check if there's a prepared ConfigMap file in `/root/k8s-app/configmaps/`

### 3. Create Missing Resources

After identifying the issue, create the missing ConfigMap:

```bash
# List available ConfigMap files
ls -la /root/k8s-app/configmaps/

# Review the ConfigMap content
cat /root/k8s-app/configmaps/nginx-config.yaml

# Apply the ConfigMap
kubectl apply -f /root/k8s-app/configmaps/nginx-config.yaml

# Watch the frontend pod start
kubectl get pods -n webapp -l app=frontend -w
```

### 4. Verify Frontend Pod and Service

After creating the ConfigMap, verify the pod starts:

```bash
# Check pod status
kubectl get pods -n webapp -l app=frontend

# Check pod logs for nginx startup
kubectl logs deployment/frontend -n webapp

# Verify nginx config inside pod (optional)
kubectl exec -it deployment/frontend -n webapp -- nginx -t
```

### 5. Verify Frontend Service

Verify the frontend service created in Step 2:

```bash
# Check if frontend-service exists
kubectl get svc frontend-service -n webapp

# Verify service has endpoints now that pod is running
kubectl get endpoints frontend-service -n webapp

# Should show the frontend pod IP
# Example: 192.168.0.11:80
```

**Note:** Frontend service should have been created in Step 2. If missing, refer back to Step 2 to create it.

### 6. Create Ingress Configuration

Now create an ingress to expose the application externally:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: webapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  rules:
  - host: webapp.local
    http:
      paths:
      - path: /api/(.*)
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  - http:  # Default rule without host
      paths:
      - path: /api/(.*)
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
EOF
```

### 7. Test External Access

Get the ingress IP and test access:

```bash
# Get ingress status
kubectl get ingress webapp-ingress -n webapp

# Get the ingress NodePort
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
echo "Ingress NodePort: $INGRESS_PORT"

# Test from terminal
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/api/health
```

### 8. Access from Browser (Killercoda)

Use Killercoda's Traffic Port Accessor feature:

1. Click **"Traffic Port Accessor"** button (top right of screen)
2. Enter the NodePort number from above
3. Access the application in your browser
4. Test both frontend (/) and API (/api/health) endpoints

**Note:** The Host header requirement can be bypassed by using Killercoda's traffic accessor or by testing from the terminal.

## Expected Results

After completing this step:
- Frontend deployment should be running successfully
- Ingress should route traffic to correct services
- Application should be accessible from outside the cluster
- Both frontend and API endpoints should respond

## Verification Commands

```bash
# Check all pods are running
kubectl get pods -n webapp

# Test ingress routing
kubectl get ingress -n webapp

# Get NodePort and test
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/

# Check frontend logs
kubectl logs deployment/frontend -n webapp

# Verify all services are working
kubectl get svc,endpoints -n webapp
```

**Next**: Optimize resources and perform final verification of the complete application stack.