# Step 1: Analyze Consul Issues

## Task

Understand the current state of Consul and identify all configuration issues.

## Instructions

1. **Check Docker containers** (REQUIRED for verification):
   ```bash
   docker ps -a
   ```

2. **Check Consul logs**:
   ```bash
   docker logs consul 2>&1 | tail -20
   ```

3. **Examine Consul configuration**:
   ```bash
   cat /root/consul-config.json
   ```

4. **Check service registration files**:
   ```bash
   cat /root/web-service.json
   cat /root/api-service.json
   ```

5. **Test Consul API**:
   ```bash
   curl http://localhost:8500/v1/status/leader
   curl http://localhost:8500/v1/catalog/services
   ```

6. **Check the reference configuration**:
   ```bash
   cat /tmp/reference/consul-reference.json
   ```

## Issues to Identify

### Consul Server Issues
- [ ] Bind address `127.0.0.1` won't work inside Docker container
- [ ] Bootstrap expect is 3 but only 1 server is running
- [ ] Client address `127.0.0.1` prevents external access
- [ ] Invalid encryption key format
- [ ] DNS port changed from standard 8600 to 8601

### Service Registration Issues
- [ ] Web service health check on wrong port (8081 vs 8080)
- [ ] API service uses script check but script doesn't exist
- [ ] Database service referenced but not running
- [ ] Health check timeout too short (1s)

### ACL Issues
- [ ] ACL enabled with deny policy but no tokens configured
- [ ] Master token is empty
- [ ] No agent tokens defined

### Service Mesh Issues
- [ ] Connect proxy references non-existent database service
- [ ] CA private key is empty
- [ ] Mesh gateway mode set to remote but no gateway exists

## Common Consul Errors

### Bootstrap Expect Mismatch
```
Error: Bootstrap expects 3 servers but only 1 found
```

### Bind Address Error
```
Error: Failed to parse bind address
```

### ACL Denial
```
Error: Permission denied (ACL token required)
```

## Understanding Consul Architecture

```
┌─────────────┐     ┌─────────────┐
│   Service   │────▶│   Consul    │
│Registration │     │   Server    │
└─────────────┘     └─────────────┘
                           │
                    ┌──────▼──────┐
                    │  Catalog/   │
                    │   Registry  │
                    └─────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Service   │    │   Health    │    │     DNS     │
│  Discovery  │    │   Checks    │    │   Interface │
└─────────────┘    └─────────────┘    └─────────────┘
```

Once you understand all issues, proceed to fix them.