# Step 4: Configure Ingress and External Access

## Overview

In this step, you'll fix the ingress configuration to enable external access to the application. The current ingress has wrong service references and missing configurations.

## Current Problems

Based on the current setup:
- Frontend deployment is **ContainerCreating** - references non-existent ConfigMap (`nginx-config-missing`)
- Frontend service doesn't exist yet
- No ingress configuration has been created
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

### 2. Create Missing ConfigMap for Frontend

The frontend pod is stuck in ContainerCreating because it references `nginx-config-missing`. Let's investigate and fix:

```bash
# Check what ConfigMap the frontend deployment is looking for
kubectl describe deployment frontend -n webapp | grep -A 5 "Volumes:"

# Check the broken deployment
kubectl describe pod -l app=frontend -n webapp

# You'll see: MountVolume.SetUp failed - configmap "nginx-config-missing" not found
```

**Fix - Apply the prepared ConfigMap:**

```bash
# Check the ConfigMap file (already prepared in setup)
cat /root/k8s-app/configmaps/nginx-config.yaml

# Apply it
kubectl apply -f /root/k8s-app/configmaps/nginx-config.yaml

# Watch the frontend pod start
kubectl get pods -n webapp -l app=frontend -w
```

### 3. Verify Frontend Pod Status

After creating the ConfigMap, check if the frontend pod starts:

```bash
# Watch the frontend pod status
kubectl get pods -n webapp -l app=frontend

# Once running, check pod logs for nginx startup
kubectl logs deployment/frontend -n webapp

# Look for successful startup messages:
# ✅ "start worker process"
# ✅ nginx successfully started
# ❌ If you see "config" errors, check ConfigMap content

# Verify the ConfigMap was created
kubectl get configmap nginx-config-missing -n webapp

# Optional: Verify nginx config inside pod
kubectl exec -it deployment/frontend -n webapp -- nginx -t
# Expected: "configuration file /etc/nginx/nginx.conf syntax is ok"
```

### 4. Verify Frontend Service

Check if the frontend service exists (should have been created in Step 2):

```bash
# Check if frontend-service exists
kubectl get svc frontend-service -n webapp

# If it doesn't exist, create it:
kubectl apply -f - <<EOF
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

# Verify service and endpoints
kubectl get svc,endpoints -n webapp | grep frontend

# Endpoints should now show the frontend pod IP
# Example: endpoints/frontend-service   192.168.0.11:80
```

### 5. Create Ingress Configuration

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

### 6. Test External Access

Get the ingress IP and test access:

```bash
# Get ingress status and IP
kubectl get ingress webapp-ingress -n webapp

# Get the ingress controller service IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# If LoadBalancer not available, get NodePort
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Test access to the application (using NodePort)
curl -H "Host: webapp.local" http://$NODE_IP:$INGRESS_PORT/

# Test API endpoint
curl -H "Host: webapp.local" http://$NODE_IP:$INGRESS_PORT/api/health
```

### 7. Add Host Entry (if needed)

If testing with domain name:

```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Add to /etc/hosts for local testing
echo "$NODE_IP webapp.local" | sudo tee -a /etc/hosts

# Then test with NodePort:
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
curl http://webapp.local:$INGRESS_PORT/
```

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
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl -H "Host: webapp.local" http://$NODE_IP:$INGRESS_PORT/

# Check frontend logs
kubectl logs deployment/frontend -n webapp

# Verify all services are working
kubectl get svc,endpoints -n webapp
```

**Next**: Optimize resources and perform final verification of the complete application stack.