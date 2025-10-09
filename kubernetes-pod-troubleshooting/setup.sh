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
        image: postgres:13-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: webapp
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "64Mi"
            cpu: "500m"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-data
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
        - containerPort: 80
        volumeMounts:
        - name: api-config
          mountPath: /etc/nginx/conf.d
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
      volumes:
      - name: api-config
        configMap:
          name: api-config
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
    app: backend
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
          name: nginx-config
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
  storageClassName: fast-ssd
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
            name: frontend-service-wrong
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

# Create solution ConfigMaps (for reference/hints)
echo "📝 Creating solution ConfigMaps..."

cat > /root/k8s-app/configmaps/api-config.yaml << 'EOF'
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

cat > /root/k8s-app/configmaps/nginx-config.yaml << 'EOF'
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
        }
    }
EOF

# Note: Solution files removed - users should investigate and fix using kubectl commands

# Apply all broken manifests
echo "🔥 Applying broken configurations from files..."
kubectl apply -f /root/k8s-app/deployments/
kubectl apply -f /root/k8s-app/services/
kubectl apply -f /root/k8s-app/storage/
kubectl apply -f /root/k8s-app/ingress/

# Wait for pods to start failing
echo "⏳ Waiting for pods to start..."
sleep 15

# Copy verify scripts to /usr/local/bin for easy access
echo "📋 Installing verify scripts..."
cat > /usr/local/bin/verify-step2 << 'VERIFY_EOF'
#!/bin/bash
echo "Verifying Step 2: Service Communication and API Pods..."

# Check if API pods are running
API_RUNNING=$(kubectl get pods -n webapp -l app=api --no-headers 2>/dev/null | grep -c "Running")
API_READY=$(kubectl get pods -n webapp -l app=api -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null | grep -o "true" | wc -l)

echo "API pods running: $API_RUNNING"
echo "API pods ready: $API_READY"

ERRORS=0

if [ $API_RUNNING -lt 2 ]; then
    echo "❌ API pods are not running (expected 2, found $API_RUNNING)"
    ((ERRORS++))
else
    echo "✅ API pods are running"
fi

if [ $API_READY -lt 2 ]; then
    echo "❌ API pods are not ready (expected 2, found $API_READY)"
    ((ERRORS++))
else
    echo "✅ API pods are ready"
fi

# Check specific services
REQUIRED_SERVICES=("api-service" "frontend-service" "postgres-service" "redis-cache")
MISSING_SERVICES=0

echo ""
for service in "${REQUIRED_SERVICES[@]}"; do
    if kubectl get svc $service -n webapp >/dev/null 2>&1; then
        echo "✅ Service $service exists"
        ENDPOINTS=$(kubectl get endpoints $service -n webapp -o jsonpath='{.subsets[0].addresses}' 2>/dev/null)
        if [ -n "$ENDPOINTS" ] && [ "$ENDPOINTS" != "null" ]; then
            echo "  ✅ Service $service has endpoints"
        else
            echo "  ❌ Service $service has no endpoints"
            ((MISSING_SERVICES++))
        fi
    else
        echo "❌ Service $service is missing"
        ((MISSING_SERVICES++))
    fi
done

# Check API service selector
API_SELECTOR=$(kubectl get svc api-service -n webapp -o jsonpath='{.spec.selector.app}' 2>/dev/null)
if [ "$API_SELECTOR" = "api" ]; then
    echo "✅ API service has correct selector"
else
    echo "❌ API service selector is incorrect: $API_SELECTOR (should be 'api')"
    ((MISSING_SERVICES++))
fi

TOTAL_ERRORS=$((ERRORS + MISSING_SERVICES))

echo ""
if [ $TOTAL_ERRORS -eq 0 ]; then
    echo "✅ Step 2 verification passed!"
    echo "Proceed to Step 3."
    exit 0
else
    echo "❌ Step 2 verification failed!"
    echo "$TOTAL_ERRORS issues found"
    exit 1
fi
VERIFY_EOF

chmod +x /usr/local/bin/verify-step2

# Create README for troubleshooting guidance
cat > /root/k8s-app/README.md << 'EOF'
# Kubernetes Pod Troubleshooting Lab

## Overview
This lab contains intentionally broken Kubernetes configurations for troubleshooting practice.

## Directory Structure
```
k8s-app/
├── README.md
├── deployments/
│   ├── api-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── postgres-deployment.yaml
│   └── redis-deployment.yaml
├── services/
│   └── api-service.yaml
├── storage/
│   └── postgres-pvc.yaml
├── ingress/
│   └── webapp-ingress.yaml
└── configmaps/
    ├── api-config.yaml (for Step 2)
    └── nginx-config.yaml (for Step 4)
```

## Your Mission
Investigate and fix issues with:
1. **Pods**: Multiple pods not running - use kubectl describe to find why
2. **Services**: Check if endpoints are being created properly
3. **Storage**: Verify PVC and storage class configuration
4. **ConfigMaps**: Some pods may need configuration files
5. **Ingress**: External access configuration

## Note About API
The API is a mock service using nginx to return JSON responses (not a real backend app).
This keeps the focus on Kubernetes troubleshooting rather than application development.

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