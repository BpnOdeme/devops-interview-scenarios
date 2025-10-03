#!/bin/bash

# Killercoda Kubernetes Pod Troubleshooting Setup
# This script runs on kubernetes-kubeadm-1node image which has kubectl and cluster ready

echo "🚀 Setting up Kubernetes Pod Troubleshooting Scenario..."

# Wait for Kubernetes cluster to be fully ready
echo "⏳ Waiting for Kubernetes cluster to be ready..."
until kubectl get nodes | grep -w Ready; do
  echo "Waiting for node to be ready..."
  sleep 5
done

echo "✅ Kubernetes cluster is ready!"
kubectl get nodes

# Create webapp namespace
echo "📁 Creating webapp namespace..."
kubectl create namespace webapp

# Deploy broken PostgreSQL (wrong image tag)
echo "💣 Deploying broken PostgreSQL..."
cat << 'EOF' | kubectl apply -f -
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
        image: postgres:13-wrong  # Intentionally wrong image
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: webapp
        # Missing POSTGRES_USER and POSTGRES_PASSWORD
        resources:
          requests:
            memory: "64Mi"  # Too low memory
            cpu: "250m"
          limits:
            memory: "64Mi"  # Too low memory
            cpu: "500m"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc-wrong  # Wrong PVC name
EOF

# Deploy broken API service (wrong selector)
echo "💣 Deploying broken API service..."
cat << 'EOF' | kubectl apply -f -
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
        image: node:16-alpine
        command: ["/bin/sh"]
        args: ["-c", "npm start"]  # Will fail - no package.json
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@postgres-wrong:5432/webapp"  # Wrong service name
        - name: REDIS_URL
          value: "redis://redis-cache:6379"
        resources:
          requests:
            memory: "32Mi"   # Too low for Node.js
            cpu: "100m"
          limits:
            memory: "64Mi"   # Too low for Node.js
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: webapp
spec:
  selector:
    app: backend  # Wrong selector - should be 'api'
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF

# Deploy broken frontend (missing ConfigMap)
echo "💣 Deploying broken frontend..."
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
        - name: static-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config-missing  # ConfigMap doesn't exist
      - name: static-content
        emptyDir: {}
EOF

# Deploy broken PVC (wrong storage class)
echo "💣 Deploying broken PVC..."
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd-missing  # Non-existent storage class
  resources:
    requests:
      storage: 1Gi
EOF

# Deploy broken ingress (wrong service names)
echo "💣 Deploying broken ingress..."
cat << 'EOF' | kubectl apply -f -
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
            name: frontend-service-wrong  # Wrong service name
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

# Deploy working Redis (for comparison)
echo "✅ Deploying working Redis for comparison..."
cat << 'EOF' | kubectl apply -f -
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

# Wait for pods to start failing
echo "⏳ Waiting for pods to start..."
sleep 15

echo ""
echo "✅ Setup complete! Broken application deployed."
echo ""
echo "🔍 Current cluster status:"
kubectl get nodes
echo ""
echo "📦 Pods in webapp namespace (should show various failures):"
kubectl get pods -n webapp
echo ""
echo "🎯 Your mission: Fix all the failing pods and get the application running!"
echo ""
echo "💡 Start investigating with:"
echo "   kubectl get pods -n webapp"
echo "   kubectl describe pod <pod-name> -n webapp"
echo "   kubectl get events -n webapp --sort-by=.lastTimestamp"