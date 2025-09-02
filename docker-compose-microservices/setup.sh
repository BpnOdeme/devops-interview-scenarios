#!/bin/bash

set -e

echo "Setting up broken microservices environment..."

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create project directory
mkdir -p /root/microservices
cd /root/microservices

# Create BROKEN docker-compose.yml with multiple issues
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  frontend:
    image: nginx:alpine
    ports:
      - "80:80"
    depends_on:
      - api
    networks:
      - frontend-net
    volumes:
      - ./html:/usr/share/nginx/html
    # ISSUE: Frontend not in backend network - cannot reach API
    
  api:
    image: node:14-alpine
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=database       # ISSUE: Wrong service name (should be 'db')
      - DB_PORT=3307           # ISSUE: Wrong port (should be 3306)
      - REDIS_HOST=redis-cache # ISSUE: Wrong service name (should be 'cache')
      - REDIS_PORT=6379
    depends_on:
      - db
      - cache
    networks:
      - backend-net
      - frontend              # ISSUE: Wrong network name (should be 'frontend-net')
    command: npm start
    working_dir: /app
    # ISSUE: No volume mount for application code
    
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: appdb
      MYSQL_PASSWORD: apppass  # ISSUE: MYSQL_USER not defined
    ports:
      - "3306:3306"
    networks:
      - db-net                 # ISSUE: Not in same network as API
    volumes:
      - db-data:/var/lib/mysql
      
  cache:
    image: redis:6-alpine
    ports:
      - "6379:6380"            # ISSUE: Port mapping incorrect (host:container reversed)
    networks:
      - cache-net              # ISSUE: Not in same network as API
    command: redis-server --requirepass secretpass  # ISSUE: Password not configured in API

networks:
  frontend-net:
    driver: bridge
  backend-net:
    driver: bridge
  db-net:
    driver: bridge
  cache-net:
    driver: overlay            # ISSUE: Overlay driver requires swarm mode

volumes:
  db-data:
    driver: local
  app-data:                    # ISSUE: Unused volume defined
EOF

# Create API directory with broken/missing files
mkdir -p api
cat > api/package.json <<'EOF'
{
  "name": "microservices-api",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.17.1",
    "mysql2": "^2.2.5",
    "redis": "^3.1.2"
  }
}
EOF

# Create incomplete API server (missing but referenced in docker-compose)
cat > api/index.js <<'EOF'
// TODO: Implement API server
// This file needs to be completed
EOF

# Create nginx config with wrong upstream
mkdir -p html
cat > html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Microservices App</title>
</head>
<body>
    <h1>Frontend Placeholder</h1>
    <!-- TODO: Add API integration -->
</body>
</html>
EOF

# Create nginx config that references wrong API endpoint
mkdir -p nginx
cat > nginx/default.conf <<'EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /api {
        proxy_pass http://api-server:3001;  # ISSUE: Wrong service name and port
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Create conflicting Docker network
docker network create backend-net --subnet=172.20.0.0/16 2>/dev/null || true

# Set wrong permissions on docker-compose.yml
chmod 000 docker-compose.yml

# Create a reference file for students
mkdir -p /tmp/reference
cat > /tmp/reference/docker-compose-reference.yml <<'EOF'
# Reference Docker Compose Configuration
# This is a working example for a microservices architecture

version: '3.8'

services:
  frontend:
    image: nginx:alpine
    ports:
      - "80:80"
    depends_on:
      - api
    networks:
      - app-network
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf

  api:
    image: node:14-alpine
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_USER=appuser
      - DB_PASSWORD=apppass
      - DB_NAME=appdb
      - REDIS_HOST=cache
      - REDIS_PORT=6379
      - REDIS_PASSWORD=secretpass
    depends_on:
      - db
      - cache
    networks:
      - app-network
    volumes:
      - ./api:/app
    command: npm start
    working_dir: /app

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: appdb
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppass
    ports:
      - "3306:3306"
    networks:
      - app-network
    volumes:
      - db-data:/var/lib/mysql

  cache:
    image: redis:6-alpine
    ports:
      - "6379:6379"
    networks:
      - app-network
    command: redis-server --requirepass secretpass

networks:
  app-network:
    driver: bridge

volumes:
  db-data:
    driver: local
EOF

echo ""
echo "Broken microservices environment created!"
echo ""
echo "Issues to fix:"
echo "1. Permission denied on docker-compose.yml"
echo "2. Network configuration problems"
echo "3. Service name mismatches"
echo "4. Port configuration errors"
echo "5. Missing application code"
echo "6. Environment variable issues"
echo ""
echo "Start by fixing the file permissions!"