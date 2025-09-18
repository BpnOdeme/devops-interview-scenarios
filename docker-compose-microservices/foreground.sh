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
echo "Waiting for setup to complete..."
# Wait for setup.sh to complete (max 30 seconds)
for i in {1..30}; do
    if [ -d /root/microservices ]; then
        break
    fi
    sleep 1
done

echo "Checking project structure..."
if [ -d /root/microservices ]; then
    cd /root/microservices
    echo "[✓] Project directory found"
else
    echo "[✗] Project directory not found - Setup may have failed"
    echo "Please wait a moment for setup to complete or run: ./setup.sh"
fi

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