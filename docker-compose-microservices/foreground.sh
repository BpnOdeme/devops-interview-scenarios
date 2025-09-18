#!/bin/bash

echo "Welcome to Docker Compose Microservices Troubleshooting!"
echo ""

# Run setup if directory doesn't exist
if [ ! -d /root/microservices ]; then
    echo "Setting up the environment..."
    # Find and run setup.sh
    if [ -f ./setup.sh ]; then
        bash ./setup.sh
    elif [ -f /tmp/setup.sh ]; then
        bash /tmp/setup.sh
    elif [ -f ~/setup.sh ]; then
        bash ~/setup.sh
    else
        echo "[!] Setup script not found, creating environment manually..."
        # Create the environment inline if setup.sh is not found
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/BpnOdeme/devops-interview-scenarios/main/docker-compose-microservices/setup.sh)" 2>/dev/null || \
        # If curl fails, create minimal environment
        (
            mkdir -p /root/microservices
            cd /root/microservices
            echo "Minimal environment created"
        )
    fi
fi

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

# Now check for project directory
if [ -d /root/microservices ]; then
    cd /root/microservices
    echo "[✓] Project directory found at /root/microservices"
else
    echo "[✗] Failed to create project directory"
    echo "Creating it now..."
    mkdir -p /root/microservices
    cd /root/microservices
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
echo "Your mission: Find and fix all Docker Compose configuration issues"
echo ""
echo "💡 Start by navigating to the project directory:"
echo "   cd /root/microservices"
echo ""
echo "Then investigate what's wrong..."