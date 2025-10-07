# Webapp API

Simple Node.js API for Kubernetes troubleshooting lab.

## Features

- Express.js REST API
- PostgreSQL database connectivity
- Redis cache connectivity
- Health check endpoint with service status
- Comprehensive logging for troubleshooting

## Endpoints

- `GET /` - API information
- `GET /health` - Health check (includes DB and Redis status)
- `GET /users` - Database query example
- `GET /cache/test` - Redis cache test

## Environment Variables

- `PORT` - Server port (default: 3000)
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection URL

## Building Docker Image

```bash
docker build -t your-registry/webapp-api:1.0 .
docker push your-registry/webapp-api:1.0
```

## For Lab Use

This application is designed for Kubernetes troubleshooting scenarios. It intentionally:
- Logs connection attempts and errors
- Provides detailed health check information
- Shows clear error messages for debugging
