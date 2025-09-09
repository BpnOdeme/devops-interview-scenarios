#!/bin/bash

# Check if nginx configuration is valid
nginx -t > /tmp/nginx_test 2>&1

if grep -q "syntax is ok" /tmp/nginx_test && grep -q "test is successful" /tmp/nginx_test; then
    # Check if nginx is running by checking for the process
    if pgrep nginx > /dev/null; then
        echo "done"
        exit 0
    else
        echo "Configuration is valid but Nginx is not running. Start it with: nginx"
        exit 1
    fi
else
    echo "Nginx configuration still has errors. Run 'nginx -t' to see details."
    exit 1
fi