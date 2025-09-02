# Step 4: Test the Stack

## Task

Start the microservices stack and verify all services are working correctly.

## Instructions

1. Start the Docker Compose stack:
   ```bash
   cd /root/microservices
   docker-compose up -d
   ```

2. Check if all services are running:
   ```bash
   docker-compose ps
   ```
   
   All services should show as "Up" status.

3. Check service logs for any errors:
   ```bash
   docker-compose logs api
   docker-compose logs db
   docker-compose logs cache
   docker-compose logs frontend
   ```

4. Test the API endpoint:
   ```bash
   curl http://localhost:3000/health
   ```
   
   Expected response:
   ```json
   {"status":"healthy","service":"api"}
   ```

5. Test the frontend:
   ```bash
   curl http://localhost/
   ```
   
   Should return the HTML page.

6. Test the frontend-to-API proxy:
   ```bash
   curl http://localhost/api
   ```
   
   Expected response:
   ```json
   {"message":"API is working!"}
   ```

7. Verify database connectivity:
   ```bash
   docker-compose exec db mysql -u appuser -papppass -e "SELECT 1;"
   ```

8. Verify Redis connectivity:
   ```bash
   docker-compose exec cache redis-cli -a secretpass ping
   ```
   
   Should return: `PONG`

9. Check network connectivity between services:
   ```bash
   docker-compose exec api ping -c 2 db
   docker-compose exec api ping -c 2 cache
   docker-compose exec frontend ping -c 2 api
   ```

## Monitoring Commands

- View real-time logs: `docker-compose logs -f`
- Check resource usage: `docker stats`
- Inspect network: `docker network inspect microservices_app-network`
- Execute commands in containers: `docker-compose exec [service] [command]`

## Success Criteria

✅ All services are running (status: Up)
✅ No errors in service logs
✅ API health check returns successful response
✅ Frontend can reach API through proxy
✅ Database accepts connections
✅ Redis responds to ping
✅ Services can communicate over the network

## Troubleshooting

If services fail to start:
- Check logs: `docker-compose logs [service]`
- Verify port availability: `netstat -tlnp | grep [port]`
- Check Docker resources: `docker system df`
- Restart individual service: `docker-compose restart [service]`