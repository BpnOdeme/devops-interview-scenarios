#!/bin/bash

# Verification script for Step 2: Fix Service Communication

echo "Verifying Step 2: Service Communication..."

# Check if services exist and have correct selectors
SERVICES_COUNT=$(kubectl get svc -n webapp --no-headers | wc -l)
ENDPOINTS_COUNT=$(kubectl get endpoints -n webapp --no-headers | grep -v "<none>" | wc -l)

echo "Services found: $SERVICES_COUNT"
echo "Services with endpoints: $ENDPOINTS_COUNT"

# Check specific services
REQUIRED_SERVICES=("api-service" "frontend-service" "postgres-service" "redis-cache")
MISSING_SERVICES=0

for service in "${REQUIRED_SERVICES[@]}"; do
    if kubectl get svc $service -n webapp >/dev/null 2>&1; then
        echo "✅ Service $service exists"

        # Check if service has endpoints
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

if [ $MISSING_SERVICES -eq 0 ]; then
    echo ""
    echo "✅ Step 2 verification passed!"
    echo "All services are properly configured and have endpoints."
    echo "Proceed to Step 3 to fix storage and database issues."
    exit 0
else
    echo ""
    echo "❌ Step 2 verification failed!"
    echo "$MISSING_SERVICES service issues remain."
    echo "Fix the service configurations and try again."
    exit 1
fi