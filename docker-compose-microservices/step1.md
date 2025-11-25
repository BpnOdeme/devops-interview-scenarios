# Step 1: Initial Investigation and Access

## Objective

Gain access to the configuration files and perform an initial analysis of the infrastructure setup. Understanding what you're working with is critical before making any changes.

## Background

In production troubleshooting scenarios, the first challenge is often gaining access to configuration files and understanding the current state of the system. File permissions, ownership, and configuration structure all play crucial roles.

## Investigation Tasks

### 1. Navigate to the Project Directory

```bash
cd /root/microservices
```

### 2. Inspect File Permissions

Check the permissions on all configuration files, particularly the Docker Compose file:

```bash
ls -la
```

**Questions to consider:**
- Can you read the docker-compose.yml file?
- What are the current file permissions?
- Why might file permissions be preventing access?

### 3. Resolve Permission Issues

If you cannot read critical configuration files, investigate why and fix the permission issues.

**Hint:** Docker Compose files typically need to be readable (at minimum) to be used. Consider what chmod value would be appropriate.

### 4. Examine the Docker Compose Configuration

Once you have access, examine the current configuration:

```bash
cat docker-compose.yml
```

**Analyze the following aspects:**

#### Network Configuration
- How many networks are defined?
- Which services are on which networks?
- Can services that need to communicate reach each other?
- Are the network drivers appropriate for single-host deployments?

#### Service Definitions
- What services are defined?
- What images are they using?
- What ports are exposed?
- What environment variables are configured?

#### Dependencies
- Which services depend on others?
- Is the startup order logical?
- Are there any circular dependencies?

#### Volumes
- What volumes are mounted?
- Is application code properly mounted into containers?
- Are persistent data volumes defined?

### 5. Check the Reference Configuration

Compare the broken configuration with the reference:

```bash
cat /tmp/reference/docker-compose-reference.yml
```

**Key comparison points:**
- Network topology differences
- Environment variable values
- Port mappings
- Service names and references

### 6. Check Existing Docker Resources

See if there are any pre-existing Docker networks that might conflict:

```bash
docker network ls
```

Look for networks with similar names or subnet ranges that might cause conflicts.

### 7. Examine Application Structure

Check what application files exist:

```bash
ls -la api/
ls -la nginx/
ls -la html/
```

**Verify:**
- Is the API code present?
- Is the nginx configuration available?
- Does the frontend HTML exist?

## What to Look For

As a middle-level DevOps engineer, you should be identifying:

### Critical Issues
- **Permissions**: Files that cannot be accessed or modified
- **Network Isolation**: Services on different networks that need to communicate
- **Service References**: Mismatches between environment variables and actual service names
- **Port Misconfigurations**: Wrong port numbers or incorrect mappings
- **Missing Resources**: Absent volumes, ConfigMaps, or code directories

### Architectural Concerns
- **Network Driver Compatibility**: Is the driver suitable for the deployment environment?
- **Resource Dependencies**: Are services starting in the correct order?
- **Data Persistence**: Are databases and caches properly configured with volumes?

## Documentation

Create mental notes or a scratch file documenting:

- [ ] Permission issues found
- [ ] Network configuration problems
- [ ] Service naming inconsistencies
- [ ] Port configuration errors
- [ ] Missing or misconfigured volumes
- [ ] Environment variable issues
- [ ] Docker resource conflicts

## Expected Outcome

By the end of this step, you should:

1. Have read access to all configuration files
2. Understand the intended architecture (4 services: frontend, api, db, cache)
3. Have identified multiple configuration issues (without fixing them yet)
4. Understand which services need to communicate with each other
5. Have a mental model of what needs to be fixed

## Hints

- File permissions in Linux are controlled by `chmod`. Common readable permissions include 644 (rw-r--r--) or 664 (rw-rw-r--)
- In Docker Compose, services communicate using service names as DNS hostnames
- The `depends_on` directive controls startup order but doesn't guarantee readiness
- Network driver `overlay` requires Docker Swarm mode; `bridge` is for single-host setups
- Port mappings follow the format `host:container`, not the reverse

## Next Steps

Once you've completed your investigation and documented the issues, proceed to Step 2 where you'll begin fixing the network configuration.

**Remember**: Good troubleshooting is methodical. Don't rush to fix things without understanding the root causes first.
