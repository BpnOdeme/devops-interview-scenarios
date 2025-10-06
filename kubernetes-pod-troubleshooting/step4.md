# Step 4: Configure Ingress and External Access

## Overview

In this step, you'll fix the ingress configuration to enable external access to the application. The current ingress has wrong service references and missing configurations.

## Current Problems

Based on the current setup:
- Frontend deployment is **ContainerCreating** - references non-existent ConfigMap (`nginx-config-missing`)
- Frontend service doesn't exist yet
- No ingress configuration has been created
- Ingress controller should be enabled via minikube addons

## Tasks

### 1. Check Ingress Controller Status

First, verify the ingress controller is running:

```bash
# Check if ingress addon is enabled (for minikube)
minikube addons list | grep ingress

# Check ingress controller pods
kubectl get pods -n ingress-nginx

# If not enabled, enable it
minikube addons enable ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 2. Create Missing ConfigMap for Frontend

The frontend pod is stuck in ContainerCreating because it references `nginx-config-missing`. Let's create the correct ConfigMap:

```bash
# Check what ConfigMap the frontend deployment is looking for
kubectl describe deployment frontend -n webapp | grep -A 5 "Volumes:"

# Create the nginx-config ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config-missing  # Must match the deployment reference
  namespace: webapp
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
            try_files $uri $uri/ /index.html;
        }

        location /api/ {
            proxy_pass http://api-service:3000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }
EOF
```

### 3. Verify Frontend Pod Status

After creating the ConfigMap, check if the frontend pod starts:

```bash
# Watch the frontend pod status
kubectl get pods -n webapp -w

# Once running, check pod logs
kubectl logs deployment/frontend -n webapp

# Verify the ConfigMap was created
kubectl get configmap nginx-config-missing -n webapp
```

### 4. Create Frontend Service

The frontend needs a service for ingress to route traffic to it:

```bash
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
# Get ingress IP (for minikube)
minikube ip

# Or get ingress status
kubectl get ingress webapp-ingress -n webapp

# Test access to the application
curl -H "Host: webapp.local" http://$(minikube ip)/

# Test API endpoint
curl -H "Host: webapp.local" http://$(minikube ip)/api/health
```

### 7. Add Host Entry (if needed)

If testing with domain name:

```bash
# Add to /etc/hosts for local testing
echo "$(minikube ip) webapp.local" >> /etc/hosts

# Then test with:
curl http://webapp.local/
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
curl -H "Host: webapp.local" http://$(minikube ip)/

# Check frontend logs
kubectl logs deployment/frontend -n webapp

# Verify all services are working
kubectl get svc,endpoints -n webapp
```

**Next**: Optimize resources and perform final verification of the complete application stack.