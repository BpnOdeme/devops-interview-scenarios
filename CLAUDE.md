# Software Development Best Practices

- Always develop with clean code principles and clean architecture
- Focus on maintaining a clear, maintainable, and scalable code structure
- Pay attention to naming conventions. Apply them in every operation you perform

## User Interaction Memories

- When asked to show user memories, write out the existing memories from the file
- When asked what was previously added, display the content that was previously added to the memory file

## Git Workflow

- Her git commit atmadan önce mutlaka rootdaki CLAUDE.md file güncelle
- Her commit atıldığında root dizindeki CLAUDE.md file güncelle, md fileları güncelle

## Recent Work - Kubernetes Pod Troubleshooting Scenario Updates (2025-10-06)

### Updated Step Descriptions and Setup to Match Real Cluster State

#### Modified setup script to make API pods fail initially:

**Changed API deployment behavior:**
- API pods now crash with CrashLoopBackOff (exit 1 loop simulating missing package.json)
- Added failing liveness probe to force pod restarts
- This ensures all critical pods (Frontend, Postgres, API) are failing at start

#### Aligned all step documentation with actual setup script behavior:

1. **Step 1 - Diagnose Pod Failures**:
   - Updated expected findings to match real initial state
   - Frontend: ContainerCreating (missing ConfigMap: nginx-config-missing)
   - Postgres: Pending (wrong image tag: postgres:13-wrong, no PVC)
   - **API: CrashLoopBackOff (container exits, failing liveness probe)**
   - Redis: Running (healthy reference pod)
   - Added more specific common issue patterns

2. **Step 2 - Fix Service Communication and API Pods**:
   - **Added API pod fix as first task** (create ConfigMap with working Node.js code)
   - Corrected service selector fix (app: backend → app: api)
   - Added commands for creating missing services (frontend-service, postgres-service)
   - Updated DATABASE_URL fix instructions
   - Updated verify-step2.sh to check API pods are Running and Ready (2/2)
   - Improved verification commands

3. **Step 3 - Resolve Storage and Database Issues**:
   - Changed from "fix PVC" to "create PVC" (since it doesn't exist initially)
   - Updated postgres deployment fixes (image, env vars, memory, volume)
   - Added proper storage class detection commands
   - Clearer issue identification

4. **Step 4 - Configure Ingress and External Access**:
   - Updated to create ConfigMap with correct name (nginx-config-missing)
   - Added ingress controller verification steps
   - Created frontend service
   - Simplified ingress creation process

5. **Step 5 - Optimize Resources and Verify Stack**:
   - Removed API fix section (now handled in Step 2)
   - Focused on resource monitoring and optimization
   - Enhanced end-to-end testing procedures
   - Added comprehensive health check verification

#### Previous Work - Kubernetes Pod Troubleshooting Scenario (2025-10-03)

### Added New Kubernetes Troubleshooting Case

#### Created comprehensive Kubernetes troubleshooting scenario:

1. **Complete Kubernetes Environment**:
   - Minikube cluster with intentional issues
   - Multi-component application (Frontend, API, Database, Cache)
   - Broken deployments, services, ingress, and storage
   - Real-world troubleshooting scenarios

2. **5-Step Progressive Troubleshooting**:
   - Step 1: Pod failure diagnosis (CrashLoopBackOff, ImagePullBackOff)
   - Step 2: Service communication and networking fixes
   - Step 3: Storage and database connectivity resolution
   - Step 4: Ingress configuration and external access
   - Step 5: Resource optimization and end-to-end verification

3. **Comprehensive Learning Experience**:
   - kubectl debugging commands
   - Service selectors and endpoints
   - PersistentVolume and storage classes
   - ConfigMaps and Secrets management
   - Resource limits and health checks
   - Ingress controller configuration

4. **Production-Ready Skills**:
   - Systematic debugging approach
   - Real-world problem scenarios
   - Best practices implementation
   - Complete application stack troubleshooting

#### Technical Implementation:
- **Setup Script**: Automated broken cluster deployment
- **Verification Scripts**: Automated step validation
- **Progressive Difficulty**: From basic pod issues to complex networking
- **Realistic Problems**: Mirror actual production failures
- **Comprehensive Documentation**: Detailed step-by-step guidance

This scenario fills the gap between Docker Compose and more advanced DevOps tools, providing essential Kubernetes troubleshooting skills for middle-level engineers.

## Previous Work - Docker Compose Microservices Scenario (2025-09-09)

### Comprehensive Microservices Architecture Implementation

#### Created complete microservices ecosystem with:

1. **API Gateway Service** (Port 3000):
   - Express.js based central routing
   - Rate limiting with express-rate-limit
   - Security headers with Helmet.js
   - HTTP proxy middleware for service routing
   - Comprehensive logging with Winston
   - Health check endpoints

2. **User Service** (Port 3001):
   - User registration and authentication
   - JWT token generation and validation
   - Password hashing with bcrypt
   - MongoDB for user data persistence
   - Redis for session management
   - Input validation with Joi
   - RESTful API endpoints

3. **Product Service** (Port 3002):
   - Product catalog management
   - Inventory tracking with stock operations
   - Category management
   - Redis caching for performance
   - Full-text search with MongoDB indexes
   - Pagination support
   - Soft delete functionality

4. **Order Service** (Port 3003):
   - Order processing workflow
   - Integration with Product Service for inventory
   - RabbitMQ for event publishing
   - Order status management
   - Payment status tracking
   - Order history with status timeline
   - User order retrieval

5. **Frontend Dashboard**:
   - Real-time service health monitoring
   - Interactive testing interface
   - Service status indicators
   - Test data creation buttons
   - Responsive modern UI
   - Connection status for each service

6. **Infrastructure Components**:
   - MongoDB: Separate databases per service
   - Redis: Caching and session store
   - RabbitMQ: Message queue for async communication
   - Nginx: Frontend serving and reverse proxy
   - Docker networking with isolated subnets

#### Technical Implementation Details:
- **Clean Architecture**: Separation of concerns with clear service boundaries
- **Error Handling**: Comprehensive try-catch blocks with proper error responses
- **Logging**: Winston logger integration across all services
- **Validation**: Joi schema validation for all inputs
- **Security**: JWT authentication, bcrypt hashing, Helmet.js headers
- **Health Checks**: All services expose /health endpoints
- **Docker Setup**: Individual Dockerfiles optimized for production
- **Environment Management**: Proper .env configuration examples
- **Network Isolation**: Services communicate through Docker bridge network

#### Troubleshooting Scenario Features:
- Intentionally broken setup.sh for learning purposes
- Missing api/index.js file to simulate common issues
- Network configuration problems to solve
- Service name mismatches in docker-compose
- Port mapping errors
- File permission issues
- Database connection challenges

#### Benefits:
- Production-ready microservices architecture
- Scalable and maintainable code structure
- Comprehensive error handling and logging
- Security best practices implementation
- Easy testing with interactive dashboard
- Real-world troubleshooting experience