#!/bin/bash

# Improved Kubernetes Pod Troubleshooting Setup with Physical Files
# This creates actual YAML files for GitOps workflow and applies them

echo "🚀 Setting up Kubernetes Pod Troubleshooting Scenario..."

# Wait for Kubernetes cluster to be fully ready
echo "⏳ Waiting for Kubernetes cluster to be ready..."
until kubectl get nodes | grep -w Ready; do
  echo "Waiting for node to be ready..."
  sleep 5
done

echo "✅ Kubernetes cluster is ready!"
kubectl get nodes

# Create directory structure for GitOps workflow
echo "📁 Setting up GitOps directory structure..."
mkdir -p /root/k8s-app/{deployments,services,storage,ingress,configmaps}
kubectl create namespace webapp

# Create broken PostgreSQL deployment
echo "💣 Creating broken PostgreSQL deployment..."
cat > /root/k8s-app/deployments/postgres-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: webapp
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
        image: postgres:13-wrong  # BROKEN: Wrong image tag
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: webapp
        # BROKEN: Missing POSTGRES_USER and POSTGRES_PASSWORD
        resources:
          requests:
            memory: "64Mi"  # BROKEN: Too low memory
            cpu: "250m"
          limits:
            memory: "64Mi"  # BROKEN: Too low memory
            cpu: "500m"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc-wrong  # BROKEN: Wrong PVC name
EOF

# Create broken API deployment
echo "💣 Creating broken API deployment..."
cat > /root/k8s-app/deployments/api-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: webapp
spec:
  replicas: 2
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
        image: nginx:1.21
        ports:
        - containerPort: 80  # BROKEN: Wrong port (should be 3000 for API)
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@postgres-wrong:5432/webapp"  # BROKEN: Wrong service name
        - name: REDIS_URL
          value: "redis://redis-cache:6379"
        resources:
          requests:
            memory: "32Mi"   # BROKEN: Too low
            cpu: "100m"
          limits:
            memory: "64Mi"   # BROKEN: Too low
            cpu: "200m"
EOF

# Create broken API service
echo "💣 Creating broken API service..."
cat > /root/k8s-app/services/api-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: webapp
spec:
  selector:
    app: backend  # BROKEN: Wrong selector - should be 'api'
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF

# Create broken frontend deployment
echo "💣 Creating broken frontend deployment..."
cat > /root/k8s-app/deployments/frontend-deployment.yaml << 'EOF'
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
        - name: static-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config-missing  # BROKEN: ConfigMap doesn't exist
      - name: static-content
        emptyDir: {}
EOF

# Create broken PVC
echo "💣 Creating broken PVC..."
cat > /root/k8s-app/storage/postgres-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd-missing  # BROKEN: Non-existent storage class
  resources:
    requests:
      storage: 1Gi
EOF

# Create broken ingress
echo "💣 Creating broken ingress..."
cat > /root/k8s-app/ingress/webapp-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: webapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: webapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service-wrong  # BROKEN: Wrong service name
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
EOF

# Create working Redis (for comparison)
echo "✅ Creating working Redis deployment..."
cat > /root/k8s-app/deployments/redis-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: webapp
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
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cache
  namespace: webapp
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
EOF

# Apply all broken manifests
echo "🔥 Applying broken configurations from files..."
kubectl apply -f /root/k8s-app/deployments/
kubectl apply -f /root/k8s-app/services/
kubectl apply -f /root/k8s-app/storage/
kubectl apply -f /root/k8s-app/ingress/

# Wait for pods to start failing
echo "⏳ Waiting for pods to start..."
sleep 15

# Create README for troubleshooting guidance
cat > /root/k8s-app/README.md << 'EOF'
# Kubernetes Pod Troubleshooting Lab

## Overview
This lab contains intentionally broken Kubernetes configurations for troubleshooting practice.

## Directory Structure
```
k8s-app/
├── deployments/     # Application deployments
├── services/        # Service definitions
├── storage/         # PVC and storage configs
├── ingress/         # Ingress configurations
└── configmaps/      # ConfigMap definitions (create as needed)
```

## Known Issues to Fix
1. **PostgreSQL**: Wrong image tag, missing env vars, low resources
2. **API**: Wrong container port, low resource limits, wrong service references
3. **Frontend**: Missing ConfigMap references
4. **Services**: Wrong selectors
5. **Storage**: Non-existent storage classes
6. **Ingress**: Wrong service references

## Troubleshooting Commands
```bash
kubectl get pods -n webapp
kubectl describe pod <pod-name> -n webapp
kubectl logs <pod-name> -n webapp
kubectl get events -n webapp --sort-by=.lastTimestamp
```

## Fixing Workflow
1. Edit YAML files in respective directories
2. Apply changes: `kubectl apply -f <file>`
3. Verify fixes: `kubectl get pods -n webapp`
4. Repeat until all pods are Running
EOF

echo ""
echo "✅ Setup complete! Broken application deployed with physical files."
echo ""
echo "🔍 Current cluster status:"
kubectl get nodes
echo ""
echo "📦 Pods in webapp namespace (should show various failures):"
kubectl get pods -n webapp
echo ""
echo "📁 Files created in /root/k8s-app/ for GitOps workflow:"
ls -la /root/k8s-app/
echo ""
echo "🎯 Your mission: Fix all the failing pods using the YAML files!"
echo ""
echo "💡 Start investigating with:"
echo "   cd /root/k8s-app"
echo "   kubectl get pods -n webapp"
echo "   kubectl describe pod <pod-name> -n webapp"
echo "   vim deployments/<deployment-name>.yaml"