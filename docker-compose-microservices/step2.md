# Step 2: Fix Network Configuration

## Task

Fix the network configuration so all services can communicate properly.

## Instructions

1. Edit the docker-compose.yml file:
   ```bash
   nano /root/microservices/docker-compose.yml
   ```
   Or use vim:
   ```bash
   vim /root/microservices/docker-compose.yml
   ```

2. Fix the network issues:

### Network Consolidation Strategy

Instead of having separate networks for each service, use a unified network architecture:

```yaml
networks:
  app-network:
    driver: bridge
```

### Service Network Assignments

Update each service to use the correct network:

- **Frontend**: Should be on the same network as API
- **API**: Should be on the same network as DB and Cache
- **DB**: Should be on the same network as API
- **Cache**: Should be on the same network as API

### Fix These Specific Issues:

1. **Frontend service**:
   - Add `app-network` to networks section
   - Remove `frontend-net`

2. **API service**:
   - Change `frontend` to `frontend-net` or better yet, use single `app-network`
   - Ensure it's on same network as DB and Cache

3. **DB service**:
   - Change `db-net` to `app-network`

4. **Cache service**:
   - Change `cache-net` to `app-network`

5. **Networks section**:
   - Change overlay driver to bridge for cache-net
   - Or simplify to single `app-network`

3. Remove conflicting Docker network if it exists:
   ```bash
   docker network rm backend-net 2>/dev/null || true
   ```

4. Validate the configuration:
   ```bash
   docker-compose config
   ```

## Best Practice

Use a single network for all services in a small microservices stack:
```yaml
services:
  frontend:
    networks:
      - app-network
  api:
    networks:
      - app-network
  db:
    networks:
      - app-network
  cache:
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

This ensures all services can communicate while maintaining isolation from other Docker stacks.