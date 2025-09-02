#!/bin/bash

# Check if health checks are passing
HEALTH_STATUS=$(curl -s http://localhost:8500/v1/health/state/passing 2>/dev/null)

# Check if we have any passing health checks
if [ -z "$HEALTH_STATUS" ] || [ "$HEALTH_STATUS" = "[]" ]; then
    echo "No passing health checks found"
    exit 1
fi

# Check if web service has passing health check
WEB_HEALTH=$(curl -s http://localhost:8500/v1/health/service/web 2>/dev/null | jq -r '.[].Checks[] | select(.CheckID != "serfHealth") | .Status' | head -1)
if [ "$WEB_HEALTH" != "passing" ]; then
    echo "Web service health check is not passing"
    exit 1
fi

echo "done"
exit 0