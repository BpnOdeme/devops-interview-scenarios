# Docker Compose Microservices Architecture

## Overview
A comprehensive microservices architecture built with Node.js, featuring multiple services communicating through REST APIs and message queues.

## Architecture Components

### Services
1. **API Gateway** (Port 3000)
   - Central entry point for all client requests
   - Routes requests to appropriate microservices
   - Implements rate limiting and security headers

2. **User Service** (Port 3001)
   - User registration and authentication
   - JWT token generation
   - User profile management
   - Session management with Redis

3. **Product Service** (Port 3002)
   - Product catalog management
   - Inventory tracking
   - Category management
   - Product caching with Redis

4. **Order Service** (Port 3003)
   - Order processing
   - Payment status tracking
   - Integration with Product Service for inventory
   - Event publishing via RabbitMQ

### Infrastructure
- **MongoDB**: Primary database for all services
- **Redis**: Caching and session management
- **RabbitMQ**: Message queue for async communication
- **Nginx**: Frontend web server and reverse proxy

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ (for local development)
- 8GB RAM minimum recommended

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd docker-compose-microservices
```

2. Install dependencies for each service:
```bash
for service in api-gateway user-service product-service order-service; do
  cd $service && npm install && cd ..
done
```

3. Start the services:
```bash
docker-compose up -d
```

4. Verify all services are running:
```bash
docker-compose ps
```

5. Access the application:
- Frontend: http://localhost
- API Gateway: http://localhost:3000
- RabbitMQ Management: http://localhost:15672 (guest/guest)

## API Endpoints

### User Service
- `POST /api/users/register` - Register new user
- `POST /api/users/login` - User login
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Product Service
- `POST /api/products` - Create product
- `GET /api/products` - List products (with pagination)
- `GET /api/products/:id` - Get product by ID
- `PUT /api/products/:id` - Update product
- `PATCH /api/products/:id/stock` - Update stock
- `DELETE /api/products/:id` - Soft delete product
- `GET /api/categories` - List categories

### Order Service
- `POST /api/orders` - Create order
- `GET /api/orders` - List orders (with pagination)
- `GET /api/orders/:id` - Get order by ID
- `PATCH /api/orders/:id/status` - Update order status
- `PATCH /api/orders/:id/payment` - Update payment status
- `GET /api/orders/user/:userId` - Get user's orders

## Development

### Running Services Locally
```bash
# Terminal 1 - MongoDB
docker run -d -p 27017:27017 --name mongodb mongo:6

# Terminal 2 - Redis
docker run -d -p 6379:6379 --name redis redis:7-alpine

# Terminal 3 - RabbitMQ
docker run -d -p 5672:5672 -p 15672:15672 --name rabbitmq rabbitmq:3-management-alpine

# Terminal 4-7 - Start each service
cd api-gateway && npm start
cd user-service && npm start
cd product-service && npm start
cd order-service && npm start
```

### Environment Variables
Copy `.env.example` to `.env` and update values as needed:
```bash
cp .env.example .env
```

## Testing

### Health Checks
All services expose health endpoints:
```bash
curl http://localhost:3000/health  # API Gateway
curl http://localhost:3001/health  # User Service
curl http://localhost:3002/health  # Product Service
curl http://localhost:3003/health  # Order Service
```

### Sample Test Flow
```bash
# 1. Create a user
curl -X POST http://localhost:3000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'

# 2. Create a product
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","description":"Test description","price":99.99,"category":"Electronics","sku":"TEST001","stock":100}'

# 3. Create an order
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"<user-id>","userEmail":"test@example.com","items":[{"productId":"<product-id>","quantity":2}],"shippingAddress":{"street":"123 Main St","city":"Test City","zipCode":"12345","country":"USA"},"paymentMethod":"credit_card"}'
```

## Monitoring

### Logs
```bash
# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f user-service
```

### Service Status
Access the frontend dashboard at http://localhost to view real-time service status and metrics.

## Troubleshooting

### Common Issues

1. **Services can't connect to MongoDB**
   - Check MongoDB is running: `docker ps | grep mongodb`
   - Verify network connectivity: `docker network ls`

2. **Redis connection errors**
   - Check Redis is running: `docker ps | grep redis`
   - Test connection: `docker exec -it redis redis-cli ping`

3. **Port conflicts**
   - Check for port usage: `netstat -tulpn | grep <port>`
   - Modify ports in docker-compose.yml if needed

4. **Memory issues**
   - Increase Docker memory allocation
   - Reduce service replicas

### Cleanup
```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: Deletes all data)
docker-compose down -v

# Clean up everything
docker system prune -a --volumes
```

## Architecture Decisions

### Technology Choices
- **Node.js**: Lightweight, fast, perfect for microservices
- **Express**: Minimal, flexible web framework
- **MongoDB**: Document database for flexible schemas
- **Redis**: High-performance caching and sessions
- **RabbitMQ**: Reliable message queuing
- **Docker Compose**: Simple orchestration for development

### Design Patterns
- **API Gateway Pattern**: Single entry point for clients
- **Database per Service**: Each service owns its data
- **Event-Driven Communication**: Async messaging via RabbitMQ
- **Circuit Breaker**: Service resilience (via proxy middleware)
- **Cache-Aside Pattern**: Redis caching for performance

## Security Considerations
- JWT authentication for API access
- Password hashing with bcrypt
- Rate limiting on API Gateway
- Helmet.js for security headers
- Environment-based configuration
- Network isolation via Docker networks

## Performance Optimizations
- Redis caching for frequently accessed data
- MongoDB indexes for query optimization
- Connection pooling for databases
- Pagination for large datasets
- Health checks for service monitoring
- Graceful shutdown handling

## License
MIT