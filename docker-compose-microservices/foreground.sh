#!/bin/bash

echo "Welcome to Docker Compose Microservices Troubleshooting!"
echo ""
echo "Checking Docker environment..."
echo ""

# Check Docker daemon
if docker info >/dev/null 2>&1; then
    echo "[✓] Docker daemon is running"
else
    echo "[✗] Docker daemon is NOT running"
fi

# Check Docker Compose
if command -v docker-compose >/dev/null 2>&1; then
    echo "[✓] Docker Compose is installed ($(docker-compose --version))"
else
    echo "[✗] Docker Compose is NOT installed"
fi

echo ""
echo "Checking project structure..."
cd /root/microservices 2>/dev/null || echo "[!] Project directory not found"

# Try to read docker-compose.yml
if [ -r docker-compose.yml ]; then
    echo "[✓] docker-compose.yml is readable"
else
    echo "[✗] docker-compose.yml has permission issues!"
    ls -la docker-compose.yml 2>/dev/null
fi

echo ""
echo "Checking for Docker networks..."
docker network ls | grep -E "(backend-net|frontend-net|db-net|cache-net)" || echo "[!] No project networks found"

echo ""
echo "[!] Multiple issues detected in the microservices stack!"
echo ""
echo "Your first task: Fix the permission issue with docker-compose.yml"
echo "Location: /root/microservices/docker-compose.yml"
echo ""
echo "Type 'cd /root/microservices' to navigate to the project directory"