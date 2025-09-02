# Step 3: Test Load Balancing

## Task

Verify that the load balancer is distributing traffic correctly across all backend servers.

## Instructions

1. Test the load balancer multiple times to see traffic distribution:
   ```bash
   for i in {1..10}; do curl -s http://localhost/ | grep "Backend"; done
   ```

2. Check the health endpoint:
   ```bash
   curl http://localhost/health
   ```

3. Monitor Nginx access logs to see requests being distributed:
   ```bash
   tail -f /var/log/nginx/access.log
   ```
   (Press Ctrl+C to stop monitoring)

4. Test load balancing with concurrent requests:
   ```bash
   for i in {1..20}; do curl -s http://localhost/ & done | grep "Backend" | sort | uniq -c
   ```

5. Verify the ip_hash algorithm is working by making requests with the same IP:
   ```bash
   for i in {1..5}; do curl -s http://localhost/; sleep 1; done
   ```

## Expected Results

You should see:
- Responses from all three backend servers
- Backend 2 receiving roughly twice as many requests (weight=2)
- Health checks returning JSON responses
- Consistent backend selection for the same client IP (due to ip_hash)

## Advanced Testing

Try stopping one backend server and verify failover:
```bash
# Find and kill backend 2 process
ps aux | grep "backend2"
# Kill the process using: kill <PID>

# Test again
for i in {1..10}; do curl -s http://localhost/; done
```

The load balancer should automatically route traffic to the remaining healthy servers.