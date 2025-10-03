# Step 4: Configure Ingress and External Access

## Overview

In this step, you'll fix the ingress configuration to enable external access to the application. The current ingress has wrong service references and missing configurations.

## Current Problems

- Ingress references non-existent services
- Frontend deployment is missing required ConfigMap
- No proper routing configuration
- Ingress controller may not be properly configured

## Tasks

### 1. Check Ingress Status

First, examine the current ingress configuration:

```bash
# Check ingress status
kubectl get ingress -n webapp
kubectl describe ingress webapp-ingress -n webapp

# Check ingress controller
kubectl get pods -n ingress-nginx
# or for minikube
kubectl get pods -n kube-system | grep ingress
```

### 2. Create Missing ConfigMap for Frontend

The frontend pod references a non-existent ConfigMap. Create it:

```bash
# Create nginx configuration for frontend
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
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

### 3. Create Basic Frontend Content

Add some basic HTML content for testing:

```bash
# Create a simple index.html
cat << 'EOF' | kubectl create configmap frontend-content --from-literal=index.html='
<!DOCTYPE html>
<html>
<head>
    <title>WebApp</title>
</head>
<body>
    <h1>Welcome to WebApp</h1>
    <p>Frontend is working!</p>
    <p><a href="/api/health">Check API Health</a></p>
</body>
</html>
' -n webapp
EOF
```

### 4. Update Frontend Deployment

Fix the frontend deployment to use the correct ConfigMaps:

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
        - name: frontend-content
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
      - name: frontend-content
        configMap:
          name: frontend-content
EOF
```

### 5. Fix Ingress Configuration

Update the ingress to reference correct services:

```bash
cat << 'EOF' | kubectl apply -f -
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