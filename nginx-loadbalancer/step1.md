# Step 1: Investigate the Issue

## Task

First, let's understand what's wrong with the Nginx load balancer configuration.

## Instructions

Run these commands in order:

1. **First, check the Nginx configuration syntax** (REQUIRED for verification):
   ```bash
   nginx -t
   ```
   This will show you syntax errors in the configuration.

2. View the current configuration to identify issues:
   ```bash
   cat /etc/nginx/sites-available/loadbalancer
   ```

3. Check if backend servers are running:
   ```bash
   curl http://127.0.0.1:8081/
   curl http://127.0.0.1:8082/
   curl http://127.0.0.1:8083/
   ```

4. Review Nginx error logs (optional):
   ```bash
   tail -20 /var/log/nginx/error.log
   ```

## What to Look For

- Syntax errors in the configuration
- Missing semicolons
- Typos in directive names
- Incorrect proxy settings
- Missing brackets or braces

## Hint

Pay attention to:
- Each upstream server definition should end with a semicolon
- Directive names must be spelled correctly
- All location blocks must be properly closed

Once you've identified the issues, proceed to the next step to fix them.