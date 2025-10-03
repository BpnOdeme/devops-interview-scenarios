#!/bin/bash

# Kubernetes Pod Troubleshooting - Setup Script
# This script sets up a broken Kubernetes environment for troubleshooting

echo "Setting up Kubernetes cluster with intentional issues..."

# Install required tools
apt-get update > /dev/null 2>&1
apt-get install -y curl wget jq > /dev/null 2>&1

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" > /dev/null 2>&1
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 > /dev/null 2>&1
chmod +x minikube
mv minikube /usr/local/bin/

# Install docker (faster for Killercoda)
apt-get install -y docker.io > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1
systemctl enable docker > /dev/null 2>&1

# Add user to docker group
usermod -aG docker $USER > /dev/null 2>&1

echo "Starting Kubernetes cluster..."
# Start minikube with lighter configuration for faster startup
minikube start --driver=docker --memory=2048mb --cpus=2 --kubernetes-version=v1.28.0 --wait=false &

# Give minikube time to start
sleep 30

echo "Waiting for Kubernetes cluster to be ready..."
# Shorter timeout and better feedback
timeout 180 kubectl wait --for=condition=Ready nodes --all --timeout=180s || {
    echo "Cluster startup taking longer than expected, continuing with setup..."
}

# Enable ingress addon
minikube addons enable ingress > /dev/null 2>&1

# Create directories for manifests
cd /root
mkdir -p k8s-app/{database,backend,frontend,redis,ingress,configmaps}

# Create namespace
kubectl create namespace webapp > /dev/null 2>&1

# Apply broken configurations (these will have intentional issues)
echo "Deploying broken application components..."

# Create broken database deployment (wrong image, missing env vars)
cat > /root/k8s-app/database/postgres-deployment.yaml << 'EOF'
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
        image: postgres:13-wrong  # Intentionally wrong image tag
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: webapp
        # Missing POSTGRES_USER and POSTGRES_PASSWORD
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "64Mi"  # Too low memory limit
            cpu: "500m"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc-wrong  # Wrong PVC name
EOF

# Create broken backend deployment (wrong service reference, resource issues)
cat > /root/k8s-app/backend/api-deployment.yaml << 'EOF'
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
        args: ["-c", "npm start"]  # Will fail because no package.json
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@postgres-wrong:5432/webapp"  # Wrong service name
        - name: REDIS_URL
          value: "redis://redis-cache:6379"
        resources:
          requests:
            memory: "32Mi"   # Too low
            cpu: "100m"
          limits:
            memory: "64Mi"   # Too low for Node.js
            cpu: "200m"
EOF

# Create service with wrong selector
cat > /root/k8s-app/backend/api-service.yaml << 'EOF'
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

# Create broken frontend deployment
cat > /root/k8s-app/frontend/frontend-deployment.yaml << 'EOF'
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

# Create broken ingress
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

# Create broken PVC (wrong storage class)
cat > /root/k8s-app/database/postgres-pvc.yaml << 'EOF'
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

# Apply all broken manifests
kubectl apply -f /root/k8s-app/database/ > /dev/null 2>&1
kubectl apply -f /root/k8s-app/backend/ > /dev/null 2>&1
kubectl apply -f /root/k8s-app/frontend/ > /dev/null 2>&1
kubectl apply -f /root/k8s-app/ingress/ > /dev/null 2>&1

# Create some correct resources for reference
kubectl create configmap redis-config --from-literal=redis.conf="save 900 1" -n webapp > /dev/null 2>&1

# Create a working Redis deployment for comparison
cat > /root/k8s-app/redis/redis-deployment.yaml << 'EOF'
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

kubectl apply -f /root/k8s-app/redis/ > /dev/null 2>&1

echo "Kubernetes cluster setup complete with intentional issues!"
echo "Use 'kubectl get pods -n webapp' to see the problematic pods."

# Create setup completion marker
touch /tmp/setup-complete

echo "✅ Setup process finished!"