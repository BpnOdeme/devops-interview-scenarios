#!/bin/bash

echo "Welcome to the Nginx Load Balancer Troubleshooting Scenario!"
echo ""
echo "Checking environment status..."
echo ""

# Check if backend servers are running
for i in 1 2 3; do
    if curl -s http://127.0.0.1:808${i}/ > /dev/null 2>&1; then
        echo "[✓] Backend server ${i} is running on port 808${i}"
    else
        echo "[✗] Backend server ${i} is NOT running"
    fi
done

echo ""
echo "Testing Nginx configuration..."
nginx -t 2>&1 | head -5
echo ""
echo "[!] Nginx configuration has errors and needs to be fixed!"
echo ""
echo "Configuration file location: /etc/nginx/sites-available/loadbalancer"
echo "Use 'nano' or 'vim' to edit the configuration."
echo ""
echo "Type 'clear' to clear the screen when ready to start."