#!/bin/bash

echo "Welcome to Jenkins CI/CD Pipeline Troubleshooting!"
echo ""
echo "Checking environment status..."
echo ""

# Check if Docker is running
if docker info >/dev/null 2>&1; then
    echo "[✓] Docker is running"
else
    echo "[✗] Docker is NOT running"
fi

# Check if Jenkins container is running
if docker ps | grep -q jenkins; then
    echo "[✓] Jenkins container is running"
    echo ""
    echo "Jenkins URL: http://localhost:8080"
    echo ""
    echo "Getting Jenkins initial admin password..."
    sleep 5
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "[!] Password not yet available, Jenkins still starting..."
else
    echo "[✗] Jenkins container is NOT running"
fi

echo ""
echo "Checking project structure..."
if [ -d /root/app-repo ]; then
    echo "[✓] Application repository exists at /root/app-repo"
    cd /root/app-repo
    echo ""
    echo "Repository files:"
    ls -la
else
    echo "[✗] Application repository not found"
fi

echo ""
echo "Checking for issues in Jenkinsfile..."
if [ -f /root/app-repo/Jenkinsfile ]; then
    echo "[!] Jenkinsfile exists but has multiple errors:"
    echo "    - Wrong registry URL"
    echo "    - Missing credentials"
    echo "    - Incorrect Maven commands"
    echo "    - Missing test scripts"
    echo "    - And more..."
else
    echo "[✗] Jenkinsfile not found"
fi

echo ""
echo "[!] Multiple pipeline issues detected!"
echo ""
echo "Your first task: Review and fix the Jenkinsfile"
echo "Location: /root/app-repo/Jenkinsfile"
echo ""
echo "Type 'cd /root/app-repo' to navigate to the project directory"