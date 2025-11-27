# Step 2: Fix Network Configuration

## Objective

Resolve all network configuration issues to enable proper service-to-service communication within the Docker Compose stack.

## Background

In microservices architectures, proper network configuration is fundamental to system functionality. Docker Compose creates isolated networks by default, but services need to be on compatible networks to communicate. Understanding Docker networking modes, service discovery via DNS, and network isolation principles is critical for any DevOps engineer.

## The Challenge

Based on your investigation in Step 1, you should have identified network-related issues. Your task is to fix the network configuration so that:

- All services that need to communicate can reach each other
- Service names resolve correctly via Docker's internal DNS
- Network drivers are appropriate for the deployment environment
- No conflicting networks exist

## Tasks

### 1. Analyze Current Network Topology

Review the networks section of your docker-compose.yml:

```bash
cd /root/microservices
nano docker-compose.yml  # or vim
```

**Questions to investigate:**

- How many networks are currently defined?
- Which services are assigned to which networks?
- Is there a network where all services can communicate?
- What network driver is being used?

### 2. Understand Service Communication Requirements

Map out which services need to talk to each other:

```
Frontend → API (needs to proxy requests)
API → Database (needs to query data)
API → Cache (needs to cache data)
```

**Key question**: Can all these communications happen with the current network setup?

### 3. Identify Network Driver Issues

Docker Compose supports different network drivers:

- **bridge**: Standard single-host networking (most common)
- **overlay**: Multi-host networking (requires Docker Swarm)
- **host**: Uses host's network directly (breaks isolation)
- **none**: No networking

**Investigation:**
- Which driver is currently configured?
- Is it appropriate for a single-host Docker Compose deployment?
- What driver should be used instead?

### 4. Check for Network Conflicts

Before modifying networks, check for pre-existing Docker networks that might conflict:

```bash
docker network ls
docker network inspect <network-name>
```

**If conflicts exist**, you may need to remove them:

```bash
docker network rm <network-name> 2>/dev/null || true
```

**Warning**: Only remove networks that aren't in use by running containers.

### 5. Redesign the Network Topology

Decide on the optimal network configuration:

**Option A: Single Shared Network**
- All services on one network
- Simplest approach
- Services communicate via service names

**Option B: Multiple Networks with Proper Overlap**
- Frontend on one network
- Backend services on another
- Services that need to communicate share networks

**Considerations:**
- Security: Do you need network isolation?
- Simplicity: Is a single network sufficient?
- Production Best Practices: What would you use in production?

### 6. Edit the Docker Compose Configuration

Modify the docker-compose.yml file to implement your network design.

**Things to fix:**

#### Network Definitions Section
Look at the `networks:` section at the bottom of the file. Consider:
- Should you consolidate networks?
- Is the driver correct?
- Are subnet configurations necessary?

#### Service Network Assignments
Look at each service's `networks:` section. Ensure:
- Services that need to communicate share at least one network
- Network names match those defined in the networks section
- All services are properly connected

### 7. Validate Your Configuration

Before attempting to start services, validate the syntax:

```bash
docker-compose config
```

This command will:
- Parse the YAML file
- Show the merged configuration
- Identify syntax errors
- Display the final network assignments

**Expected output**: No error messages, and you should see your network configuration clearly.

### 8. Understand Docker Service Discovery

When services are on the same Docker network:
- They can reach each other using service names as hostnames
- Docker's internal DNS resolves service names to container IPs
- Example: A service named `db` is reachable at `db:3306`

**This means**: Environment variables and configurations should use service names, not container names or external hostnames.

## Common Network Issues in Docker Compose

### Issue: Services on Different Networks
**Symptom**: Services cannot connect to each other
**Solution**: Ensure services share at least one common network

### Issue: Wrong Network Driver
**Symptom**: Network fails to create or has connectivity issues
**Solution**: Use `bridge` driver for single-host deployments

### Issue: Network Name Conflicts
**Symptom**: "network already exists" errors
**Solution**: Remove conflicting networks or rename your networks

### Issue: Typo in Network Names
**Symptom**: Service fails to start with "network not found" error
**Solution**: Ensure network names in service definitions match network definitions

## Verification Steps

After making your changes:

### 1. Validate Configuration
```bash
docker-compose config >/dev/null 2>&1 && echo "✓ Valid YAML" || echo "✗ Invalid YAML"
```

### 2. Check Network Definitions
```bash
docker-compose config | grep -A 10 "networks:"
```

### 3. Verify Service Network Assignments
For each service, check which networks it's connected to:
```bash
docker-compose config | grep -A 15 "frontend:" | grep -A 5 "networks:"
docker-compose config | grep -A 15 "api:" | grep -A 5 "networks:"
```

## Investigation Tips

- **Network topology**: Consider which services need to communicate and design accordingly
- **Network drivers**: Research the differences between bridge, overlay, host, and none drivers
- **Service discovery**: Learn how Docker Compose handles DNS resolution within networks
- **Dependencies**: Understand that `depends_on` controls startup order, not network connectivity

**Useful resources:**
- Docker network documentation
- Docker Compose networking guide
- Research: "Docker bridge vs overlay network"
- Command: `docker network inspect <network-name>`

## Expected Outcome

After completing this step:

- All services should be on compatible networks
- Network driver should be appropriate for single-host deployment
- docker-compose config should show no errors
- Services should be able to resolve each other's names (we'll test this in later steps)

## Next Steps

Once network configuration is fixed and validated, proceed to Step 3 where you'll fix service-specific configurations including environment variables, port mappings, and volume mounts.

**Remember**: Network configuration is the foundation. Without proper networking, nothing else will work, regardless of how correctly the rest is configured.
