#!/bin/bash

set -e

echo "Setting up microservices environment..."

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    apt-get update -qq
    apt-get install -y docker.io docker-compose > /dev/null 2>&1
    systemctl start docker
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    apt-get install -y docker-compose > /dev/null 2>&1
fi

# Install Node.js for local testing
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs > /dev/null 2>&1
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
    
  api:
    image: node:14-alpine
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=database
      - DB_PORT=3307
      - REDIS_HOST=redis-cache
      - REDIS_PORT=6379
    depends_on:
      - db
      - cache
    networks:
      - backend-net
      - frontend
    command: npm start
    working_dir: /app
    
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: appdb
      MYSQL_PASSWORD: apppass
    ports:
      - "3306:3306"
    networks:
      - db-net
    volumes:
      - db-data:/var/lib/mysql
      
  cache:
    image: redis:6-alpine
    ports:
      - "6379:6380"
    networks:
      - cache-net
    command: redis-server --requirepass secretpass

networks:
  frontend-net:
    driver: bridge
  backend-net:
    driver: bridge
  db-net:
    driver: bridge
  cache-net:
    driver: overlay

volumes:
  db-data:
    driver: local
  app-data:
EOF

# Create API directory with MISSING index.js file (intentional issue)
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

# Create a working API application (fixed for proper operation)
cat > api/index.js <<'EOF'
const express = require('express');
const mysql = require('mysql2');
const redis = require('redis');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// MySQL connection with proper defaults and error handling
const dbConfig = {
  host: process.env.DB_HOST || 'db',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'apppass',
  database: process.env.DB_NAME || 'appdb'
};

const db = mysql.createConnection(dbConfig);

// Connect to MySQL with retry logic
function connectToDatabase() {
  db.connect((err) => {
    if (err) {
      console.error('MySQL connection error:', err.message);
      console.log('Retrying MySQL connection in 5 seconds...');
      setTimeout(connectToDatabase, 5000);
    } else {
      console.log('Connected to MySQL database');
    }
  });
}

// Redis connection with proper defaults
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'cache',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || 'secretpass',
  retry_strategy: (options) => {
    if (options.error && options.error.code === 'ECONNREFUSED') {
      console.log('Redis connection refused, retrying...');
      return 5000;
    }
    return Math.min(options.attempt * 100, 3000);
  }
});

redisClient.on('error', err => console.log('Redis Client Error:', err.message));
redisClient.on('connect', () => console.log('Connected to Redis'));

app.get('/', (req, res) => {
  res.json({ message: 'API is running!' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'api' });
});

app.get('/api', (req, res) => {
  res.json({ message: 'API is working!' });
});

app.listen(port, () => {
  console.log(`API server listening on port ${port}`);
  // Start database connections after server starts
  connectToDatabase();
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing connections...');
  db.end();
  redisClient.quit();
  process.exit(0);
});
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
        proxy_pass http://api-server:3001;
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
echo "Microservices troubleshooting environment created!"
echo ""
echo "DevOps issues to fix (infrastructure/configuration):"
echo "1. Permission denied on docker-compose.yml (chmod 000)"
echo "2. Network configuration problems (services on different networks)"
echo "3. Service name mismatches (DB_HOST=database but service name is db)"
echo "4. Port configuration errors (Redis 6379:6380 should be 6379:6379)"
echo "5. Volume mount issues (API code not mounted)"
echo "6. Network driver issues (overlay without Swarm)"
echo "7. Nginx proxy misconfiguration (wrong service name and port)"
echo ""
echo "Note: Application code is properly written with fallback values."
echo "DevOps engineer should focus on infrastructure fixes only."
echo ""
echo "Start by fixing the file permissions: chmod 644 docker-compose.yml"