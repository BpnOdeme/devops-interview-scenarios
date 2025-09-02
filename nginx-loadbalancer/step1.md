# Step 1: Investigate the Issue

## Task

First, let's understand what's wrong with the Nginx load balancer configuration.

## Instructions

1. Check the Nginx configuration syntax:
   ```bash
   nginx -t
   ```

2. View the current configuration:
   ```bash
   cat /etc/nginx/sites-available/loadbalancer
   ```

3. Check if backend servers are running:
   ```bash
   curl http://127.0.0.1:8081/
   curl http://127.0.0.1:8082/
   curl http://127.0.0.1:8083/
   ```

4. Review Nginx error logs:
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