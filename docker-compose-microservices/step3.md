# Step 3: Fix Service Configuration and Dependencies

## Objective

Correct all service-specific configurations including environment variables, port mappings, volume mounts, and application code to ensure each service can function properly.

## Background

Even with proper network configuration, services won't work correctly if their internal configurations are wrong. Environment variables control how services connect to each other, port mappings expose services externally, volume mounts provide access to code and data, and application configurations determine how services behave.

This step requires attention to detail and understanding of how each service operates.

## The Challenge

You need to fix multiple configuration issues across all services:

- **Environment Variables**: Service references, ports, credentials must match actual configurations
- **Port Mappings**: Ensure proper host-to-container port mappings
- **Volume Mounts**: Application code and data must be accessible to containers
- **Application Configuration**: Nginx proxy configuration must route to correct services
- **Database Setup**: MySQL user and database configurations must be complete

## Tasks

### 1. Analyze API Service Configuration

The API service needs to connect to both the database and cache. Examine its environment variables:

```bash
cd /root/microservices
cat docker-compose.yml | grep -A 20 "api:"
```

**Investigate these environment variables:**

#### Database Connection Variables
- `DB_HOST`: What hostname does the API use to connect to MySQL?
- `DB_PORT`: What port number is configured?
- `DB_USER`: Is a database user specified?
- `DB_PASSWORD`: Is a password configured?
- `DB_NAME`: Is the database name specified?

#### Cache Connection Variables
- `REDIS_HOST`: What hostname does the API use to connect to Redis?
- `REDIS_PORT`: What port is configured?
- `REDIS_PASSWORD`: Is authentication configured?

**Questions to ask:**
- Do the hostname values match the service names in docker-compose.yml?
- Are the port numbers correct for MySQL (default: 3306) and Redis (default: 6379)?
- Does the API have all necessary environment variables to connect?

### 2. Verify Database Service Configuration

Check the MySQL service configuration:

```bash
cat docker-compose.yml | grep -A 15 "db:"
```

**MySQL environment variables to verify:**
- `MYSQL_ROOT_PASSWORD`: Root password (for admin access)
- `MYSQL_DATABASE`: Database name to create on startup
- `MYSQL_USER`: Application user to create
- `MYSQL_PASSWORD`: Password for the application user

**Critical check**: Do the database credentials in the API service match those defined in the MySQL service?

### 3. Examine Redis Configuration

Check the Redis (cache) service:

```bash
cat docker-compose.yml | grep -A 10 "cache:"
```

**Investigate:**
- What command is Redis running with?
- Is password authentication configured (`--requirepass`)?
- Does the password in the command match the one in API's `REDIS_PASSWORD`?

### 4. Check Port Mappings

Port mappings follow the format `"host_port:container_port"`. Review all port mappings for correctness:

**Investigation steps:**
```bash
# View all port mappings
grep -E "^\s+ports:" docker-compose.yml -A 2

# Check parsed configuration
docker-compose config | grep -E "published|target" -B 2

# Verify ports match between mappings and service expectations
```

**Things to verify:**
- Port mapping syntax is correct (format: `"host:container"`)
- Host and container ports are not reversed
- Port numbers match what the application expects
- No port conflicts between services

### 5. Verify Volume Mounts

Check if application code is properly mounted:

```bash
cat docker-compose.yml | grep -B 5 -A 3 "volumes:"
```

**API Service - Critical Volume Mount:**
- The API needs its code mounted at `/app`
- Format: `./api:/app`
- Also check for node_modules protection: `/app/node_modules`

**Frontend Service:**
- HTML content: `./html:/usr/share/nginx/html`
- Nginx config: `./nginx/default.conf:/etc/nginx/conf.d/default.conf`

**Database Service:**
- Persistent data: `db-data:/var/lib/mysql`

**Cache Service:**
- Persistent data: `cache-data:/data`

### 6. Fix Nginx Proxy Configuration

The nginx configuration determines how frontend requests are proxied to the API:

```bash
cat nginx/default.conf
```

**Check the proxy configuration:**

```nginx
location /api {
    proxy_pass http://SERVICE_NAME:PORT;
    ...
}
```

**Investigation approach:**
1. Identify the service name referenced in `proxy_pass`
2. Compare with service names defined in docker-compose.yml
3. Verify the port number matches the API application's listening port
4. Remember: Within Docker networks, services use their service names as DNS hostnames

**Verification commands:**
```bash
# List all service names
docker-compose config | grep -E "^  [a-z_-]+:" | tr -d ' :'

# Check what port the API listens on
grep -r "listen\|port" api/index.js

# Test nginx configuration syntax
docker run --rm -v $(pwd)/nginx:/etc/nginx/conf.d nginx:alpine nginx -t
```

### 7. Verify Application Code Exists

Ensure the API application code is present and complete:

```bash
ls -la api/
cat api/package.json
cat api/index.js | head -50
```

**Verify:**
- Does `api/index.js` exist?
- Is the package.json complete?
- Does the API code use environment variables correctly?

### 8. Cross-Reference All Configurations

Create a mental map of how services reference each other:

**Service Name in docker-compose.yml → How it's referenced:**
- `db` → Referenced in API's `DB_HOST` environment variable
- `cache` → Referenced in API's `REDIS_HOST` environment variable
- `api` → Referenced in nginx `proxy_pass` directive

**All references must be consistent!**

## Configuration Patterns to Understand

### Environment Variable Best Practices

```yaml
environment:
  - SERVICE_HOST=service-name  # Use docker-compose service name
  - SERVICE_PORT=1234          # Use container's internal port
  - SERVICE_USER=username
  - SERVICE_PASSWORD=password
```

### Port Mapping Format

```yaml
ports:
  - "host:container"  # Correct format
  # NOT "container:host"
```

### Volume Mount Format

```yaml
volumes:
  - ./source:/destination           # Bind mount
  - /destination/node_modules       # Anonymous volume (override)
  - volume-name:/destination        # Named volume
```

## Troubleshooting Checklist

Work through this systematically:

**Service References:**
- [ ] API's `DB_HOST` matches the database service name in docker-compose.yml
- [ ] API's `REDIS_HOST` matches the cache service name in docker-compose.yml
- [ ] Nginx's `proxy_pass` references the correct API service name

**Port Configuration:**
- [ ] API's `DB_PORT` matches the database container's exposed port
- [ ] API's `REDIS_PORT` matches the cache container's exposed port
- [ ] All port mappings use correct `host:container` format
- [ ] Port numbers are consistent across all configurations

**Environment Variables:**
- [ ] API has all required database connection variables defined
- [ ] API has all required cache connection variables defined
- [ ] Database service has complete user configuration
- [ ] Passwords and credentials match between services

**File System:**
- [ ] API application code is accessible via volume mounts
- [ ] Nginx configuration files are properly mounted
- [ ] All required application files exist and are readable

**Verification Commands:**
```bash
# Check service names
docker-compose config | grep -E "^  [a-z_-]+:"

# Verify environment variables
docker-compose config | grep -E "(DB_HOST|DB_PORT|REDIS_HOST|REDIS_PORT)" -A 1

# Check port consistency
docker-compose config | grep -E "published|target|ports" -A 2

# Cross-reference credentials
docker-compose config | grep -E "(DB_USER|DB_PASSWORD|MYSQL_USER|MYSQL_PASSWORD)" -A 1
```

## Validation Commands

After making changes:

### Validate YAML Syntax
```bash
docker-compose config
```

### Check Specific Service Configuration
```bash
docker-compose config | grep -A 25 "api:"
docker-compose config | grep -A 15 "db:"
```

### Verify Environment Variables
```bash
docker-compose config | grep -E "(DB_HOST|DB_PORT|REDIS_HOST|REDIS_PORT)"
```

## Expected Challenges

This step is intentionally complex because it mirrors real-world scenarios where:

1. **Multiple services must be configured consistently**
2. **Service names must match across different configuration files**
3. **Credentials must align between services**
4. **Port numbers must be correct and consistent**
5. **Volume mounts must provide necessary code and data**

A middle-level DevOps engineer should be able to:
- Identify mismatches between configurations
- Understand service dependencies
- Research service-specific requirements and defaults
- Recognize proper Docker Compose syntax
- Cross-reference multiple configuration sources

## Investigation Resources

- **Service documentation**: Check Docker Hub for official images (MySQL, Redis, Nginx)
- **Default ports**: Research what ports each service typically uses
- **Service discovery**: Service names in docker-compose.yml become DNS hostnames
- **Environment variables**: Values don't use quotes in YAML format
- **Configuration validation**: Use `docker-compose config` to parse and verify syntax
- **Cross-referencing**: Compare API environment variables with service definitions

**Research tips:**
```bash
# Find service documentation
docker pull mysql:8.0
docker inspect mysql:8.0 | grep -i "expose\|port"

# Check what ports services expose
docker-compose config | grep -A 10 "ports:"

# Validate environment variable format
docker-compose config | grep -E "environment:" -A 10
```

## Expected Outcome

After completing this step:

- All environment variables should reference correct service names
- Port mappings should be in correct format
- Volume mounts should provide necessary code access
- Database should have complete user configuration
- Nginx should proxy to correct API service and port
- Configuration should pass `docker-compose config` validation

## Next Steps

Once all service configurations are corrected, proceed to Step 4 where you'll start the stack and perform end-to-end testing to ensure everything works together.

**Remember**: Configuration consistency is key. One wrong environment variable or port number can break the entire stack.
