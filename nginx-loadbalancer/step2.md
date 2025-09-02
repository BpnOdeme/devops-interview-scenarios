# Step 2: Fix the Configuration

## Task

Now that you've identified the issues, fix the Nginx configuration file.

## Instructions

1. Edit the configuration file:
   ```bash
   nano /etc/nginx/sites-available/loadbalancer
   ```
   Or use vim if you prefer:
   ```bash
   vim /etc/nginx/sites-available/loadbalancer
   ```

2. Fix the following issues:
   - Add missing semicolons to upstream server definitions
   - Correct the typo: `ip_hsh` should be `ip_hash`
   - Fix `prox_pass` to `proxy_pass`
   - Add missing semicolon after `access_log off`
   - Ensure all timeout values have consistent units
   - Remove or fix the conflicting server block

3. Add missing proxy headers for better load balancing:
   ```nginx
   proxy_set_header X-Real-IP $remote_addr;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto $scheme;
   ```

4. Test your configuration:
   ```bash
   nginx -t
   ```

5. If the test passes, reload Nginx:
   ```bash
   systemctl start nginx
   systemctl reload nginx
   ```

## Expected Configuration Structure

Your upstream block should look like:
```nginx
upstream backend_servers {
    server 127.0.0.1:8081 weight=1;
    server 127.0.0.1:8082 weight=2;
    server 127.0.0.1:8083 weight=1;
    ip_hash;
}
```

## Verification

After fixing, you should see:
```
nginx: configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```