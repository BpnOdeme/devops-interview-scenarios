#!/bin/bash

# Emergency setup for immediate testing
# This script uses the simplest possible approach

echo "🚨 Emergency Kubernetes Setup - Simple and Fast"

# Method 1: Direct binary download (most compatible)
echo "📦 Installing kubectl via direct download..."
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/ 2>/dev/null || mv kubectl /usr/bin/

# Add to PATH
export PATH="/usr/local/bin:/usr/bin:$PATH"
echo 'export PATH="/usr/local/bin:/usr/bin:$PATH"' >> ~/.bashrc

# Verify
if command -v kubectl >/dev/null 2>&1; then
    echo "✅ kubectl installed successfully at: $(which kubectl)"
    kubectl version --client
else
    echo "❌ kubectl installation failed - trying alternative..."

    # Alternative: Try with wget
    wget -O kubectl "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl $HOME/bin/ 2>/dev/null || mkdir -p $HOME/bin && mv kubectl $HOME/bin/
    export PATH="$HOME/bin:$PATH"
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
fi

# Try to use existing cluster first
echo "🔍 Checking for existing cluster..."
if kubectl cluster-info 2>/dev/null | grep -q "running"; then
    echo "✅ Found working Kubernetes cluster!"
    kubectl get nodes
else
    echo "🚀 No cluster found, installing Docker and minikube..."

    # Install Docker
    apt-get update && apt-get install -y docker.io
    systemctl start docker

    # Install minikube
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    mv minikube /usr/local/bin/

    # Start minikube with simplest config
    echo "Starting minikube..."
    minikube start --driver=none --force

    # Wait a bit
    sleep 30
    kubectl wait --for=condition=Ready nodes --all --timeout=180s || echo "Cluster may need more time..."
fi

# Create webapp namespace
echo "📁 Creating webapp namespace..."
kubectl create namespace webapp 2>/dev/null || echo "Namespace might already exist"

# Create broken deployments
echo "💣 Creating broken deployments..."

# Broken postgres
kubectl apply -n webapp -f - << 'EOF'
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
EOF

# Broken API
kubectl apply -n webapp -f - << 'EOF'
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
EOF

# Working Redis for comparison
kubectl apply -n webapp -f - << 'EOF'
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
EOF

echo ""
echo "✅ Emergency setup complete!"
echo ""
echo "🔍 Current status:"
kubectl get nodes 2>/dev/null || echo "Cluster info not available"
echo ""
echo "📦 Broken pods (should show ImagePullBackOff and CrashLoopBackOff):"
kubectl get pods -n webapp 2>/dev/null || echo "Pods not ready yet"
echo ""
echo "💡 Try: kubectl get pods -n webapp"
echo "💡 Debug with: kubectl describe pod <pod-name> -n webapp"