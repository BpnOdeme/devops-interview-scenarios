# Step 2: Fix Network Configuration

## Task

Fix the network configuration so all services can communicate properly.

## Background

In a microservices architecture, proper network configuration is crucial for service communication. Docker Compose provides network isolation by default, but services need to be on the same network to communicate with each other.

## Instructions

1. Edit the docker-compose.yml file:
   ```bash
   nano /root/microservices/docker-compose.yml
   ```
   Or use vim:
   ```bash
   vim /root/microservices/docker-compose.yml
   ```

2. Analyze the current network configuration:
   - Check which networks each service is connected to
   - Identify services that need to communicate with each other
   - Look for network driver compatibility issues

3. Remove any conflicting Docker networks:
   ```bash
   docker network ls
   docker network rm <network-name> 2>/dev/null || true
   ```

4. Validate your configuration:
   ```bash
   docker-compose config
   ```

## Hints

- Services can only communicate if they're on the same network
- The `overlay` driver requires Docker Swarm mode - use `bridge` for single-host deployments
- Consider whether you need multiple networks or if a single network would suffice
- Check the reference configuration in `/tmp/reference/` for guidance

## Common Network Issues

- Services on different networks cannot resolve each other's hostnames
- Network driver incompatibility can prevent network creation
- Pre-existing networks with the same name can cause conflicts

## What to Check

- [ ] All services that need to communicate are on the same network
- [ ] Network drivers are appropriate for your deployment
- [ ] No conflicting network names exist
- [ ] Services can resolve each other by name