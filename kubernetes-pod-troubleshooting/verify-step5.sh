#!/bin/bash

# Verification script for Step 5: Final Optimization and Verification

echo "Verifying Step 5: Final Stack Verification..."

# Check if all required pods are running
REQUIRED_APPS=("frontend" "api" "postgres" "redis")
FAILED_APPS=0

for app in "${REQUIRED_APPS[@]}"; do
    POD_STATUS=$(kubectl get pod -l app=$app -n webapp -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    POD_READY=$(kubectl get pod -l app=$app -n webapp -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    if [ "$POD_STATUS" = "Running" ] && [ "$POD_READY" = "True" ]; then
        echo "✅ $app pod is running and ready"
    else
        echo "❌ $app pod status: $POD_STATUS, ready: $POD_READY"
        ((FAILED_APPS++))
    fi
done

# Check if API ConfigMap exists
if kubectl get configmap api-code -n webapp >/dev/null 2>&1; then
    echo "✅ api-code ConfigMap exists"
else
    echo "❌ api-code ConfigMap is missing"
    ((FAILED_APPS++))
fi

# Check API deployment resources
API_MEMORY=$(kubectl get deployment api -n webapp -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [ -n "$API_MEMORY" ] && [ "$API_MEMORY" != "64Mi" ]; then
    echo "✅ API has sufficient memory limits: $API_MEMORY"
else
    echo "❌ API memory limits too low: $API_MEMORY"
    ((FAILED_APPS++))
fi

# Test API health endpoint
echo "Testing API health..."
MINIKUBE_IP=$(minikube ip 2>/dev/null)
if [ -n "$MINIKUBE_IP" ]; then
    API_HEALTH=$(curl -s -H "Host: webapp.local" "http://$MINIKUBE_IP/api/health" | grep -o "healthy" 2>/dev/null)
    if [ -n "$API_HEALTH" ]; then
        echo "✅ API health endpoint is working"
    else
        echo "❌ API health endpoint is not responding"
        ((FAILED_APPS++))
    fi
else
    echo "⚠️  Cannot test API health - minikube IP not available"
fi

# Check for recent error events
ERROR_EVENTS=$(kubectl get events -n webapp --field-selector type=Warning --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -5)
if [ -z "$ERROR_EVENTS" ]; then
    echo "✅ No recent error events"
else
    echo "⚠️  Recent warning events found:"
    echo "$ERROR_EVENTS"
fi

# Count total running pods
RUNNING_PODS=$(kubectl get pods -n webapp --no-headers | grep -c "Running")
TOTAL_PODS=$(kubectl get pods -n webapp --no-headers | wc -l)

echo ""
echo "=== FINAL STATUS SUMMARY ==="
echo "Running pods: $RUNNING_PODS/$TOTAL_PODS"

if [ $FAILED_APPS -eq 0 ] && [ $RUNNING_PODS -eq $TOTAL_PODS ]; then
    echo ""
    echo "🎉 CONGRATULATIONS! 🎉"
    echo "✅ Step 5 verification passed!"
    echo "✅ All application components are running successfully"
    echo "✅ Complete Kubernetes application stack is functional"
    echo ""
    echo "Summary of what you fixed:"
    echo "  - Pod container and image issues"
    echo "  - Service networking and selectors"
    echo "  - Persistent storage configuration"
    echo "  - Database connectivity and credentials"
    echo "  - Ingress routing and external access"
    echo "  - Resource limits and application deployment"
    echo ""
    echo "You have successfully completed the Kubernetes troubleshooting scenario!"
    exit 0
else
    echo ""
    echo "❌ Step 5 verification failed!"
    echo "$FAILED_APPS issues remain to be fixed."
    echo "Review the failed components and their configurations."
    exit 1
fi