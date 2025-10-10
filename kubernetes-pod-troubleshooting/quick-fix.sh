#!/bin/bash

# Quick Fix Script - Automatically fix all issues in the scenario
# Use this for quick testing and debugging

set -e

echo "🚀 Starting Quick Fix - All Steps..."
echo ""

# Step 2: Fix API and Services
echo "📝 Step 2: Fixing API and Services..."
kubectl apply -f /root/k8s-app/configmaps/api-config.yaml
kubectl patch svc api-service -n webapp -p '{"spec":{"selector":{"app":"api"}}}'

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
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: webapp
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF

echo "✅ Step 2 completed"
sleep 3

# Step 3: Fix Storage and Database
echo ""
echo "💾 Step 3: Fixing Storage and Database..."
kubectl set image deployment/postgres postgres=postgres:15 -n webapp
kubectl delete pvc postgres-pvc -n webapp --force --grace-period=0 || true
sleep 2

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
EOF

kubectl set env deployment/postgres -n webapp \
    POSTGRES_USER=webapp_user \
    POSTGRES_PASSWORD=webapp_pass \
    POSTGRES_DB=webapp

kubectl patch deployment postgres -n webapp -p '{"spec":{"template":{"spec":{"volumes":[{"name":"postgres-storage","persistentVolumeClaim":{"claimName":"postgres-pvc"}}]}}}}'

kubectl set resources deployment/postgres -n webapp \
    --limits=memory=256Mi,cpu=500m \
    --requests=memory=128Mi,cpu=250m

echo "✅ Step 3 completed"
sleep 3

# Step 4: Configure Ingress
echo ""
echo "🌐 Step 4: Configuring Ingress..."
kubectl apply -f /root/k8s-app/configmaps/nginx-config.yaml

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: webapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: webapp.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
EOF

echo "✅ Step 4 completed"
sleep 5

# Final Status
echo ""
echo "🎯 Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all -n webapp --timeout=120s || true

echo ""
echo "📊 Final Status:"
echo ""
kubectl get pods -n webapp
echo ""
kubectl get svc -n webapp
echo ""
kubectl get ingress -n webapp

echo ""
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
echo "🌍 Ingress NodePort: $INGRESS_PORT"
echo ""
echo "🧪 Testing API:"
curl -s -H "Host: webapp.local" "http://localhost:$INGRESS_PORT/api/health" || echo "API not ready yet"

echo ""
echo ""
echo "✅ All fixes applied!"
echo ""
echo "Use Killercoda Traffic Port Accessor with port: $INGRESS_PORT"
