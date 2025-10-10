#!/bin/bash

# Quick manual deployment for testing

echo "🚀 Quick deploying broken applications..."

# Create namespace
kubectl create namespace webapp

# Deploy broken applications
kubectl apply -n webapp -f - << 'EOF'
# Broken PostgreSQL (wrong image)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-wrong
        env:
        - name: POSTGRES_DB
          value: webapp
---
# Broken API (missing package.json)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: node:16-alpine
        command: ["/bin/sh", "-c", "npm start"]
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@postgres-wrong:5432/webapp"
---
# Wrong service selector
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: backend  # Wrong selector (should be 'api')
  ports:
  - port: 3000
    targetPort: 3000
---
# Working Redis (for comparison)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:6-alpine
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cache
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
EOF

echo "✅ Deployed broken applications!"
echo ""
echo "Check with:"
echo "  kubectl get pods -n webapp"
echo "  kubectl describe pod <pod-name> -n webapp"