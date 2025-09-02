# Consul Service Discovery Troubleshooting

## Scenario Overview

You've been tasked with fixing a broken Consul service discovery deployment. The previous team attempted to set up Consul for service discovery, health checking, and service mesh capabilities, but left it in a non-functional state. Multiple microservices depend on this Consul cluster for service registration and discovery.

## The Situation

The infrastructure team reports:
- ❌ Consul server won't start properly
- ❌ Services can't register with Consul
- ❌ Health checks are failing
- ❌ Service discovery is broken
- ❌ ACL configuration is blocking access
- ❌ Service mesh proxy configuration is invalid
- ❌ UI is inaccessible from outside

## Your Mission

1. **Diagnose Consul Issues**: Identify all configuration and operational problems
2. **Fix Consul Server**: Get the Consul server running properly
3. **Fix Service Registration**: Ensure services can register correctly
4. **Configure Health Checks**: Set up proper health checking
5. **Test Service Discovery**: Verify services can discover each other

## Available Tools

- `docker` - Container management
- `consul` - Consul CLI (via docker exec)
- `curl` - Test HTTP endpoints
- `dig` - DNS lookups
- `jq` - JSON processing
- `nano/vim` - Edit configuration files

## Key Files

- `/root/consul-config.json` - Main Consul configuration
- `/root/web-service.json` - Web service registration
- `/root/api-service.json` - API service registration
- `/root/acl.json` - ACL configuration
- `/root/proxy-defaults.json` - Service mesh configuration

## Consul Components

### Service Discovery
- Service registration
- Health checks
- DNS interface (port 8600)
- HTTP API (port 8500)

### Configuration
- Key/Value store
- Watches
- Events

### Service Mesh
- Connect proxies
- Intentions
- Certificate management

## Success Criteria

- Consul server is running and accessible
- UI is accessible at http://localhost:8500
- Services can register successfully
- Health checks are passing
- DNS queries work correctly
- Service discovery functions properly

## Common Consul Commands

```bash
# Check Consul members
docker exec consul consul members

# List services
docker exec consul consul catalog services

# Register a service
docker exec consul consul services register /path/to/service.json

# Query service via DNS
dig @127.0.0.1 -p 8600 web.service.consul

# Check service health
curl http://localhost:8500/v1/health/service/web

# KV store operations
docker exec consul consul kv put key value
docker exec consul consul kv get key
```

## Important URLs

- Consul UI: http://localhost:8500/ui
- API: http://localhost:8500/v1/
- DNS: 127.0.0.1:8600

Click **START** to begin troubleshooting!