#!/bin/bash

# Simplified Kubernetes setup for Killercoda environment
# This script focuses on reliability over speed

echo "🚀 Starting Kubernetes Pod Troubleshooting Setup..."

# Update system
apt-get update -y > /dev/null 2>&1

# Install basic tools
apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release > /dev/null 2>&1

echo "📦 Installing kubectl..."

# Install kubectl via snap (most reliable for Ubuntu)
if command -v snap >/dev/null 2>&1; then
    echo "Using snap to install kubectl..."
    snap install kubectl --classic

    # Add snap bin to PATH
    export PATH="/snap/bin:$PATH"
    echo 'export PATH="/snap/bin:$PATH"' >> /root/.bashrc
else
    # Fallback to direct download
    echo "Using direct download for kubectl..."
    curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    export PATH="/usr/local/bin:$PATH"
fi

# Verify kubectl
echo "✅ Verifying kubectl installation..."
if command -v kubectl >/dev/null 2>&1; then
    echo "kubectl found at: $(which kubectl)"
    kubectl version --client --short
else
    echo "❌ kubectl installation failed!"
    exit 1
fi

echo "🐳 Installing Docker..."
# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
usermod -aG docker root

echo "☸️ Installing minikube..."
# Install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
mv minikube /usr/local/bin/

echo "🎯 Starting Kubernetes cluster..."
# Start minikube (simplified for reliability)
minikube start --driver=docker --cpus=2 --memory=2048mb --kubernetes-version=v1.28.0

# Wait for cluster
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Enable addons
echo "🔧 Enabling ingress addon..."
minikube addons enable ingress

# Create namespace and directories
echo "📁 Setting up application structure..."
kubectl create namespace webapp
mkdir -p /root/k8s-app/{deployments,services,storage,ingress,configmaps}

echo "💣 Deploying broken application components..."

# Create broken PostgreSQL deployment
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
        image: postgres:13-wrong  # Intentionally wrong image
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: webapp
        # Missing POSTGRES_USER and POSTGRES_PASSWORD
        resources:
          requests:
            memory: "64Mi"  # Too low
            cpu: "250m"
          limits:
            memory: "64Mi"  # Too low
            cpu: "500m"
EOF

# Create broken API deployment
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
        image: nginx:alpine
        ports:
        - containerPort: 80  # Wrong port - should be 3000
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@postgres-wrong:5432/webapp"  # Wrong service
        volumeMounts:
        - name: api-config
          mountPath: /etc/nginx/conf.d
        resources:
          requests:
            memory: "32Mi"   # Too low
            cpu: "100m"
          limits:
            memory: "64Mi"   # Too low
            cpu: "200m"
      volumes:
      - name: api-config
        configMap:
          name: api-config-missing  # ConfigMap doesn't exist - causes crash
EOF

# Create broken API service
cat > /root/k8s-app/services/api-service.yaml << 'EOF'
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
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config-missing  # ConfigMap doesn't exist
EOF

# Create working Redis deployment for comparison
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

# Create README before applying manifests
echo "📝 Creating README and solution files..."
cat > /root/k8s-app/README.md << 'EOF'
# Kubernetes Troubleshooting Lab

## Directory Structure

```
/root/k8s-app/
├── README.md                    # This file
├── deployments/                 # Deployment manifests
│   ├── api-deployment.yaml      # Broken API deployment
│   ├── api-deployment-SOLUTION.yaml  # Fixed version (solution reference)
│   ├── frontend-deployment.yaml
│   ├── postgres-deployment.yaml
│   └── redis-deployment.yaml
├── services/                    # Service manifests
│   └── api-service.yaml         # Broken service selector
├── storage/                     # PVC manifests (to be created)
│   └── postgres-pvc.yaml        # You need to create this
├── ingress/                     # Ingress manifests (to be created)
│   └── webapp-ingress.yaml
└── configmaps/                  # Solution hints
    ├── api-config.yaml          # Solution for API ConfigMap
    └── nginx-config.yaml        # Solution for frontend ConfigMap

## Tips

- Check *-SOLUTION.yaml files for hints
- configmaps/ directory has ready-to-use solutions
- Use `diff` to compare broken vs fixed files
EOF

# Create solution ConfigMaps
echo "Creating solution ConfigMaps in /root/k8s-app/configmaps/..."

# Frontend nginx config hint
cat > /root/k8s-app/configmaps/nginx-config.yaml << 'EOF'
# Hint: Frontend needs this ConfigMap with correct name
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config-missing  # Must match deployment reference
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
        }
    }
EOF

# API config hint
cat > /root/k8s-app/configmaps/api-config.yaml << 'EOF'
# Hint: API needs this ConfigMap to work
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
  namespace: webapp
data:
  default.conf: |
    server {
        listen 3000;
        location /health {
            return 200 '{"status":"healthy"}\n';
            add_header Content-Type application/json;
        }
        location / {
            return 200 '{"message":"API is running"}\n';
            add_header Content-Type application/json;
        }
    }
EOF

# Fixed API deployment hint
cat > /root/k8s-app/deployments/api-deployment-SOLUTION.yaml << 'EOF'
# Hint: Compare this with api-deployment.yaml to see what needs fixing
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
        image: nginx:alpine
        ports:
        - containerPort: 3000
        volumeMounts:
        - name: api-config
          mountPath: /etc/nginx/conf.d
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: api-config
        configMap:
          name: api-config
EOF

# Verify solution files were created
echo "Verifying solution files..."
ls -la /root/k8s-app/configmaps/
ls -la /root/k8s-app/deployments/*SOLUTION*

# Apply broken manifests
echo "🔥 Applying broken configurations..."
kubectl apply -f /root/k8s-app/deployments/
kubectl apply -f /root/k8s-app/services/

# Give time for pods to start failing
sleep 10

echo "✅ Setup complete!"
echo ""
echo "🔍 Current cluster status:"
kubectl get nodes
echo ""
echo "📦 Pods in webapp namespace (should show various failures):"
kubectl get pods -n webapp
echo ""
echo "🎯 Your mission: Fix all the failing pods and get the application running!"
echo ""
echo "💡 Start with: kubectl get pods -n webapp"
echo "💡 Then investigate: kubectl describe pod <pod-name> -n webapp"
echo "💡 Hint files available in /root/k8s-app/ directories (check *-fixed.yaml files)"

# Create completion marker
touch /tmp/setup-complete