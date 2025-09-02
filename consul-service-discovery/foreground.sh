#!/bin/bash

echo "Welcome to Consul Service Discovery Troubleshooting!"
echo ""
echo "Checking environment status..."
echo ""

# Check if Docker is running
if docker info >/dev/null 2>&1; then
    echo "[✓] Docker is running"
else
    echo "[✗] Docker is NOT running"
fi

# Check if Consul container exists
if docker ps -a | grep -q consul; then
    if docker ps | grep -q consul; then
        echo "[✓] Consul container is running"
    else
        echo "[✗] Consul container exists but is NOT running"
    fi
else
    echo "[✗] Consul container does NOT exist"
fi

# Check backend services
echo ""
echo "Checking backend services..."
if docker ps | grep -q web-backend; then
    echo "[✓] Web backend is running on port 8080"
else
    echo "[✗] Web backend is NOT running"
fi

if docker ps | grep -q api-backend; then
    echo "[✓] API backend is running on port 3000"
else
    echo "[✗] API backend is NOT running"
fi

# Try to access Consul
echo ""
echo "Testing Consul connectivity..."
if curl -s http://localhost:8500/v1/status/leader | grep -q "8300"; then
    echo "[✓] Consul API is responding"
else
    echo "[✗] Consul API is NOT responding"
fi

# Check for configuration files
echo ""
echo "Configuration files:"
ls -la /root/*.json 2>/dev/null | grep -E "(consul|service|acl|proxy)" || echo "[!] No configuration files found"

echo ""
echo "[!] Multiple Consul issues detected:"
echo "    - Server configuration problems"
echo "    - Service registration failures"
echo "    - Health check misconfigurations"
echo "    - ACL blocking access"
echo ""
echo "Your first task: Check Docker containers and Consul status"
echo "Start with: docker ps -a"
echo ""
echo "Working directory: /root"