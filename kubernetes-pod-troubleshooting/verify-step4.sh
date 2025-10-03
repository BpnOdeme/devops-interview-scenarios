#!/bin/bash

# Verification script for Step 4: Ingress and External Access

echo "Verifying Step 4: Ingress and External Access..."

# Check if nginx-config ConfigMap exists
if kubectl get configmap nginx-config -n webapp >/dev/null 2>&1; then
    echo "✅ nginx-config ConfigMap exists"
else
    echo "❌ nginx-config ConfigMap is missing"
    exit 1
fi

# Check frontend pod status
FRONTEND_STATUS=$(kubectl get pod -l app=frontend -n webapp -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$FRONTEND_STATUS" = "Running" ]; then
    echo "✅ Frontend pod is running"
else
    echo "❌ Frontend pod status: $FRONTEND_STATUS (should be Running)"
    exit 1
fi

# Check if frontend is ready
FRONTEND_READY=$(kubectl get pod -l app=frontend -n webapp -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$FRONTEND_READY" = "True" ]; then
    echo "✅ Frontend pod is ready"
else
    echo "❌ Frontend pod is not ready"
    exit 1
fi

# Check if ingress exists
if kubectl get ingress webapp-ingress -n webapp >/dev/null 2>&1; then
    echo "✅ webapp-ingress exists"
else
    echo "❌ webapp-ingress is missing"
    exit 1
fi

# Check ingress rules
INGRESS_RULES=$(kubectl get ingress webapp-ingress -n webapp -o jsonpath='{.spec.rules[*].http.paths[*].backend.service.name}' 2>/dev/null)
if echo "$INGRESS_RULES" | grep -q "frontend-service" && echo "$INGRESS_RULES" | grep -q "api-service"; then
    echo "✅ Ingress has correct service references"
else
    echo "❌ Ingress service references are incorrect"
    echo "Found services: $INGRESS_RULES"
    exit 1
fi

# Get minikube IP for testing
MINIKUBE_IP=$(minikube ip 2>/dev/null)
if [ -z "$MINIKUBE_IP" ]; then
    echo "⚠️  Cannot get minikube IP, skipping external access test"
else
    echo "Testing external access..."

    # Test frontend access
    FRONTEND_TEST=$(curl -s -H "Host: webapp.local" "http://$MINIKUBE_IP/" | grep -o "Welcome to WebApp" 2>/dev/null)
    if [ -n "$FRONTEND_TEST" ]; then
        echo "✅ Frontend is accessible via ingress"
    else
        echo "❌ Frontend is not accessible via ingress"
        exit 1
    fi
fi

# Check if frontend service exists and has endpoints
if kubectl get svc frontend-service -n webapp >/dev/null 2>&1; then
    echo "✅ frontend-service exists"

    FRONTEND_ENDPOINTS=$(kubectl get endpoints frontend-service -n webapp -o jsonpath='{.subsets[0].addresses}' 2>/dev/null)
    if [ -n "$FRONTEND_ENDPOINTS" ] && [ "$FRONTEND_ENDPOINTS" != "null" ]; then
        echo "✅ frontend-service has endpoints"
    else
        echo "❌ frontend-service has no endpoints"
        exit 1
    fi
else
    echo "❌ frontend-service is missing"
    exit 1
fi

echo ""
echo "✅ Step 4 verification passed!"
echo "Ingress and external access have been configured successfully."
echo "Proceed to Step 5 for final optimization and verification."
exit 0