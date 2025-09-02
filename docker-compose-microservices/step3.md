# Step 3: Fix Service Dependencies

## Task

Fix environment variables, port mappings, and service dependencies.

## Instructions

1. Continue editing docker-compose.yml to fix service configurations:

### API Service Fixes

Fix the environment variables to match actual service names:
```yaml
api:
  environment:
    - DB_HOST=db          # Changed from 'database'
    - DB_PORT=3306        # Changed from 3307
    - DB_USER=appuser     # Add this
    - DB_PASSWORD=apppass # Ensure this matches DB config
    - DB_NAME=appdb       # Add this
    - REDIS_HOST=cache    # Changed from 'redis-cache'
    - REDIS_PORT=6379     # Correct port
    - REDIS_PASSWORD=secretpass  # Add if using Redis auth
```

Add volume mount for API code:
```yaml
api:
  volumes:
    - ./api:/app
```

### Database Service Fixes

Add the missing MYSQL_USER:
```yaml
db:
  environment:
    MYSQL_ROOT_PASSWORD: secret
    MYSQL_DATABASE: appdb
    MYSQL_USER: appuser      # Add this line
    MYSQL_PASSWORD: apppass
```

### Cache Service Fixes

Fix the port mapping (format is host:container):
```yaml
cache:
  ports:
    - "6379:6379"  # Changed from "6379:6380"
```

### Frontend Service Fixes

Add nginx configuration volume:
```yaml
frontend:
  volumes:
    - ./html:/usr/share/nginx/html
    - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
```

2. Create a working API application:
   ```bash
   cat > /root/microservices/api/index.js <<'EOF'
   const express = require('express');
   const mysql = require('mysql2');
   const redis = require('redis');
   
   const app = express();
   const port = 3000;
   
   // MySQL connection
   const db = mysql.createConnection({
     host: process.env.DB_HOST,
     port: process.env.DB_PORT,
     user: process.env.DB_USER,
     password: process.env.DB_PASSWORD,
     database: process.env.DB_NAME
   });
   
   // Redis connection
   const redisClient = redis.createClient({
     host: process.env.REDIS_HOST,
     port: process.env.REDIS_PORT,
     password: process.env.REDIS_PASSWORD
   });
   
   app.get('/health', (req, res) => {
     res.json({ status: 'healthy', service: 'api' });
   });
   
   app.get('/api', (req, res) => {
     res.json({ message: 'API is working!' });
   });
   
   app.listen(port, () => {
     console.log(`API listening at http://localhost:${port}`);
   });
   EOF
   ```

3. Fix nginx configuration:
   ```bash
   cat > /root/microservices/nginx/default.conf <<'EOF'
   server {
       listen 80;
       server_name localhost;
   
       location / {
           root /usr/share/nginx/html;
           index index.html;
       }
   
       location /api {
           proxy_pass http://api:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       }
   }
   EOF
   ```

4. Validate the complete configuration:
   ```bash
   docker-compose config
   ```

## Checklist

Ensure you've fixed:
- [ ] API environment variables (DB_HOST, DB_PORT, REDIS_HOST)
- [ ] Database MYSQL_USER definition
- [ ] Redis port mapping (6379:6379)
- [ ] API volume mount (./api:/app)
- [ ] Frontend nginx config mount
- [ ] Created working API application code
- [ ] Fixed nginx proxy configuration