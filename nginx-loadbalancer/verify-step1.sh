#!/bin/bash

# Verify that the user has checked the configuration
if [ -f /tmp/nginx_checked ]; then
    echo "done"
    exit 0
fi

# Check if user ran nginx -t
if grep -q "nginx -t" ~/.bash_history 2>/dev/null; then
    touch /tmp/nginx_checked
    echo "done"
    exit 0
fi

# Check if user viewed the configuration
if grep -q "loadbalancer" ~/.bash_history 2>/dev/null; then
    touch /tmp/nginx_checked
    echo "done"
    exit 0
fi

echo "Please run 'nginx -t' to check the configuration"
exit 1