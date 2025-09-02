#!/bin/bash

# Setup script for Nginx Load Balancer scenario
set -e

echo "Setting up the environment..."

# Update package lists
apt-get update -qq

# Install required packages
apt-get install -y nginx python3 curl net-tools > /dev/null 2>&1

# Create backend application directories
mkdir -p /var/www/backend{1,2,3}

# Create simple backend applications
for i in 1 2 3; do
    cat > /var/www/backend${i}/app.py << EOF
#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'healthy', 'server': 'backend${i}'}).encode())
        else:
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(f'<h1>Response from Backend Server ${i}</h1>'.encode())
    
    def log_message(self, format, *args):
        return  # Suppress logs

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 808${i}), Handler)
    print(f'Backend ${i} running on port 808${i}')
    server.serve_forever()
EOF
    chmod +x /var/www/backend${i}/app.py
done

# Start backend servers
for i in 1 2 3; do
    nohup python3 /var/www/backend${i}/app.py > /var/log/backend${i}.log 2>&1 &
done

# Create broken Nginx configuration (intentionally broken)
cat > /etc/nginx/sites-available/loadbalancer << 'EOF'
upstream backend_servers {
    # Missing semicolons and wrong syntax
    server 127.0.0.1:8081 weight=1
    server 127.0.0.1:8082 weight=2
    server 127.0.0.1:8083 weight=1;
    
    # Typo in directive name
    ip_hsh;
    
    # Missing health check configuration
}

server {
    listen 80;
    server_name _;
    
    location / {
        # Typo in proxy_pass
        prox_pass http://backend_servers;
        
        # Missing important headers
        proxy_set_header Host $host;
        # proxy_set_header X-Real-IP $remote_addr;
        # proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # Wrong timeout format
        proxy_connect_timeout 60;
        proxy_send_timeout 60s;
        proxy_read_timeout 60sec;
    }
    
    # Health check endpoint with wrong configuration
    location /health {
        access_log off
        proxy_pass http://backend_servers/health;
    }
    
    # Missing closing brace for location
}

# Another server block that conflicts
server {
    listen 80;
    server_name _;
    
    location /status {
        stub_status on;
        access_log off;
    }
}
EOF

# Create a symlink
ln -sf /etc/nginx/sites-available/loadbalancer /etc/nginx/sites-enabled/

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Create directory for configs
mkdir -p /tmp/configs

# Create a reference configuration
cat > /tmp/configs/nginx.conf << 'EOF'
# Reference configuration for students
# This shows the correct syntax but needs to be adapted

upstream example_backend {
    server backend1.example.com:8080 weight=1;
    server backend2.example.com:8080 weight=1;
    ip_hash;
}

server {
    listen 80;
    server_name example.com;
    
    location / {
        proxy_pass http://example_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Try to reload nginx (will fail due to broken config)
nginx -t 2>/dev/null || true

# Stop nginx if it's running
systemctl stop nginx 2>/dev/null || true

echo "Environment setup complete!"
echo ""
echo "The Nginx load balancer is currently broken."
echo "Your task is to fix the configuration and get it working."
echo ""
echo "Backend servers are running on ports 8081, 8082, and 8083."
echo "Use 'nginx -t' to test your configuration."
echo ""