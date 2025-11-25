# Intentional Errors in Setup.sh

This document lists all intentional errors created by setup.sh for the troubleshooting scenario.

## Broken Docker Compose Configuration

### 1. Network Isolation (Critical)
**Error**: Services are on 4 separate networks
- `frontend` → frontend-net
- `api` → backend-net  
- `db` → db-net
- `cache` → cache-net

**Impact**: Services cannot communicate with each other
**Fix**: All services should be on `app-network`

---

### 2. Wrong Network Driver
**Error**: `cache-net` uses `overlay` driver
**Issue**: Overlay requires Docker Swarm mode (not available in single-host setup)
**Fix**: Change to `bridge` driver

---

### 3. Wrong Database Hostname
**Error**: API environment variable `DB_HOST=database`
**Issue**: Service name is `db`, not `database`
**Fix**: Change to `DB_HOST=db`

---

### 4. Wrong Database Port
**Error**: API environment variable `DB_PORT=3307`
**Issue**: MySQL runs on port 3306
**Fix**: Change to `DB_PORT=3306`

---

### 5. Wrong Redis Hostname
**Error**: API environment variable `REDIS_HOST=redis-cache`
**Issue**: Service name is `cache`, not `redis-cache`
**Fix**: Change to `REDIS_HOST=cache`

---

### 6. Reversed Port Mapping
**Error**: Cache service ports `"6379:6380"`
**Issue**: Format should be `host:container`, and Redis runs on 6379
**Fix**: Change to `"6379:6379"`

---

### 7. Missing Database User
**Error**: `MYSQL_USER` not defined in db service
**Impact**: Application user not created, API cannot connect
**Fix**: Add `MYSQL_USER: appuser`

---

### 8. Missing API Environment Variables
**Error**: API missing these environment variables:
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`
- `REDIS_PASSWORD`

**Impact**: API cannot connect to database and cache
**Fix**: Add all required environment variables

---

### 9. Missing API Volume Mount
**Error**: API has `working_dir: /app` but no volume mount
**Impact**: No application code available in container
**Fix**: Add volume `- ./api:/app`

---

### 10. Wrong Nginx Proxy Configuration
**Error**: `nginx/default.conf` has `proxy_pass http://api-server:3001`
**Issue**: Service name is `api` on port `3000`
**Fix**: Change to `proxy_pass http://api:3000`

---

### 11. File Permission Issue
**Error**: `docker-compose.yml` has `chmod 000` (no permissions)
**Impact**: File cannot be read
**Fix**: `chmod 644 docker-compose.yml`

---

### 12. Pre-existing Network Conflict
**Error**: `backend-net` network already exists (created by setup.sh)
**Impact**: May cause network creation conflicts
**Fix**: Remove existing network with `docker network rm backend-net`

---

## Summary

**Total Intentional Errors**: 12
**Difficulty Level**: Middle-Level DevOps Engineer
**Expected Fix Time**: 30-40 minutes

### Error Categories:
- **Network Issues** (3): Isolation, driver, conflicts
- **Service References** (3): Wrong hostnames/service names  
- **Port Configuration** (2): Wrong port numbers, reversed mapping
- **Missing Configuration** (3): Environment vars, volume mount, MySQL user
- **File/Proxy Issues** (2): Permissions, nginx config

All errors must be fixed for the stack to function correctly.
