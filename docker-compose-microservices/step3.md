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

Port mappings follow the format `"host_port:container_port"`. Review all port mappings:

**Frontend**: Should map host port 80 to container port 80
**API**: Should map host port 3000 to container port 3000
**Database**: Should map host port 3306 to container port 3306
**Cache**: Should map host port 6379 to container port 6379

**Common mistake**: Reversing the ports (e.g., `"6379:6380"` instead of `"6379:6379"`)

```bash
grep -E "^\s+ports:" docker-compose.yml -A 2
```

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

**Investigate:**
- What service name is referenced in `proxy_pass`?
- Does it match the actual API service name in docker-compose.yml?
- Is the port correct?
- Remember: Within Docker networks, services use their service names as hostnames

**Common issues:**
- Wrong service name (e.g., `api-server` when it should be `api`)
- Wrong port (e.g., `:3001` when it should be `:3000`)
- Using `localhost` instead of the service name

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

- [ ] API's `DB_HOST` matches database service name
- [ ] API's `DB_PORT` is correct (3306 for MySQL)
- [ ] API has `DB_USER`, `DB_PASSWORD`, `DB_NAME` configured
- [ ] Database service has `MYSQL_USER` defined
- [ ] Database credentials match between API and DB service
- [ ] API's `REDIS_HOST` matches cache service name
- [ ] API's `REDIS_PORT` is correct (6379)
- [ ] API's `REDIS_PASSWORD` matches Redis command line password
- [ ] All port mappings are in correct `host:container` format
- [ ] API code is mounted at `/app` via volumes
- [ ] Nginx config `proxy_pass` uses correct service name and port
- [ ] All required files exist (api/index.js, nginx/default.conf, etc.)

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
- Know default ports for common services
- Recognize proper Docker Compose syntax

## Hints

- MySQL default port: **3306**
- Redis default port: **6379**
- Service names in docker-compose.yml become DNS hostnames
- Environment variables in docker-compose.yml don't use quotes for values
- The reference configuration at `/tmp/reference/` shows a working example
- When in doubt, compare broken config with reference config

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
