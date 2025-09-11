# Step 3: Fix Service Dependencies

## Task

Fix environment variables, port mappings, and service dependencies.

## Instructions

1. Continue editing docker-compose.yml to fix service configurations.

2. Review environment variables:
   - Check if service names in environment variables match actual service names
   - Verify port numbers are correct
   - Ensure all required environment variables are present

3. Check port mappings:
   - Remember the format is `host:container`
   - Verify the container ports match what the service expects

4. Review volume mounts:
   - Check if application code is properly mounted
   - Verify configuration files are mounted where needed

5. Database configuration:
   - Ensure all required MySQL environment variables are set
   - Check if user credentials match between services

6. Redis configuration:
   - Verify if Redis authentication is configured consistently
   - Check port mappings

7. Verify application code:
   - Check that all necessary application files exist in the `api/` directory
   - Confirm `package.json` dependencies match what the application needs
   - Ensure the application is configured to use environment variables

8. Fix nginx configuration:
   - Check the current nginx configuration in `nginx/default.conf`
   - Verify the proxy_pass URL points to the correct service and port
   - Ensure the service name matches the one defined in docker-compose.yml

9. Validate the complete configuration:
   ```bash
   docker-compose config
   ```

## Troubleshooting Tips

- Use `docker-compose config` to validate your YAML syntax
- Check service logs with `docker-compose logs <service-name>`
- Verify environment variables with `docker-compose exec <service> env`
- Test connectivity between services using `docker exec`

## Checklist

- [ ] Environment variables correctly reference service names
- [ ] Port mappings are in correct format (host:container)
- [ ] All required MySQL environment variables are defined
- [ ] Redis authentication is consistently configured
- [ ] Application code is properly mounted
- [ ] Nginx configuration correctly proxies to API service
- [ ] Application code is properly configured