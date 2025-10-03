#!/bin/bash

# Verification script for Step 3: Storage and Database Issues

echo "Verifying Step 3: Storage and Database..."

# Check PVC status
PVC_STATUS=$(kubectl get pvc postgres-pvc -n webapp -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" = "Bound" ]; then
    echo "✅ PVC postgres-pvc is bound"
else
    echo "❌ PVC postgres-pvc status: $PVC_STATUS (should be Bound)"
    exit 1
fi

# Check postgres pod status
POSTGRES_STATUS=$(kubectl get pod -l app=postgres -n webapp -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POSTGRES_STATUS" = "Running" ]; then
    echo "✅ PostgreSQL pod is running"
else
    echo "❌ PostgreSQL pod status: $POSTGRES_STATUS (should be Running)"
    exit 1
fi

# Check if postgres is ready
POSTGRES_READY=$(kubectl get pod -l app=postgres -n webapp -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$POSTGRES_READY" = "True" ]; then
    echo "✅ PostgreSQL pod is ready"
else
    echo "❌ PostgreSQL pod is not ready"
    exit 1
fi

# Test database connectivity
echo "Testing database connectivity..."
DB_TEST=$(kubectl exec deployment/postgres -n webapp -- pg_isready -U webapp_user -d webapp 2>/dev/null)
if echo "$DB_TEST" | grep -q "accepting connections"; then
    echo "✅ Database is accepting connections"
else
    echo "❌ Database connectivity test failed"
    exit 1
fi

# Check if postgres deployment has correct image
POSTGRES_IMAGE=$(kubectl get deployment postgres -n webapp -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if echo "$POSTGRES_IMAGE" | grep -q "postgres:13"; then
    echo "✅ PostgreSQL deployment uses correct image"
else
    echo "❌ PostgreSQL deployment image: $POSTGRES_IMAGE (should contain postgres:13)"
    exit 1
fi

# Check resource limits
POSTGRES_MEMORY=$(kubectl get deployment postgres -n webapp -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [ -n "$POSTGRES_MEMORY" ] && [ "$POSTGRES_MEMORY" != "64Mi" ]; then
    echo "✅ PostgreSQL has sufficient memory limits: $POSTGRES_MEMORY"
else
    echo "❌ PostgreSQL memory limits too low: $POSTGRES_MEMORY"
    exit 1
fi

echo ""
echo "✅ Step 3 verification passed!"
echo "Storage and database issues have been resolved."
echo "Proceed to Step 4 to configure ingress and external access."
exit 0