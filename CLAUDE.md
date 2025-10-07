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

## Recent Work - Fixed API Ready Count Bug in Verify Script (2025-10-07)

### Corrected grep Pattern to Count Multiple "true" Values

**Problem:**
- verify-step2.sh reported only 1 API pod ready when both were ready
- User output showed: `API pods ready: 1` but both pods were 1/1 Running
- Script used: `grep -c "true"` which counts **lines** not occurrences
- jsonpath returns: `true true` (space-separated on one line)
- grep -c counted the line (1) instead of the word occurrences (2)

**Root Cause:**
```bash
# Wrong:
API_READY=$(... | grep -c "true")  # counts lines containing "true" = 1
# When jsonpath returns: "true true" on single line

# Should be:
API_READY=$(... | grep -o "true" | wc -l)  # counts word occurrences = 2
```

**Solution:**
- Changed `grep -c "true"` to `grep -o "true" | wc -l`
- `grep -o` outputs each match on separate line
- `wc -l` counts those lines
- Fixed in 3 places: inline verify in /usr/local/bin, /root/verify-step2.sh, verify-step2.sh

**Test:**
```bash
echo "true true" | grep -c "true"      # Returns: 1 ❌
echo "true true" | grep -o "true" | wc -l  # Returns: 2 ✅
```

---

## Previous Work - Fixed Verify Script Location for Killercoda (2025-10-07)

### Created verify-step2.sh in /root Directory During Setup

**Problem:**
- Verify scripts in git repo (verify-step2.sh) were not visible in Killercoda
- Killercoda doesn't automatically copy scripts from subdirectories to /root
- User ran `find . -name "verify-step2.sh"` in /root - nothing found
- "Check" button in Killercoda couldn't find the script

**Root Cause:**
- Files in `kubernetes-pod-troubleshooting/` subdirectory
- Killercoda needs verify scripts in `/root` directory (scenario root)
- Only files in scenario root are accessible to verify mechanism

**Solution:**
- Added code to setup.sh to create `/root/verify-step2.sh` at line 498-569
- Script is generated inline during setup (same content as inline verify in /usr/local/bin)
- Now Killercoda's "Check" button can find and execute the script
- Made executable with `chmod +x /root/verify-step2.sh`

**Implementation:**
```bash
# In setup.sh
cat > /root/verify-step2.sh << 'VERIFY_ROOT_EOF'
#!/bin/bash
# Full verification logic here
VERIFY_ROOT_EOF
chmod +x /root/verify-step2.sh
```

**Result:**
- Verify script now exists in `/root/verify-step2.sh` (Killercoda scenario root)
- Also exists in `/usr/local/bin/verify-step2` (for manual testing)
- Both versions have identical logic

---

## Previous Work - Simplified API to Mock Service (2025-10-07)

### Removed Confusing Database/Redis References from API

**Problem:**
- API deployment used nginx image but had DATABASE_URL and REDIS_URL env vars
- This was confusing - nginx can't connect to databases
- Created false expectation that this was a real backend application
- Distracted from core learning objective: Kubernetes troubleshooting

**Solution:**
- Removed DATABASE_URL and REDIS_URL environment variables
- Clarified API is a **mock service** using nginx to return JSON responses
- Added clear notes in step2.md and README.md
- Removed "Fix Backend Database Connection" section from step2.md

**Why This Matters:**
- **Focus**: This is a Kubernetes/DevOps troubleshooting scenario, not app development
- **Clarity**: Mock API with nginx is simple and fits the educational goal
- **Realistic**: In real DevOps work, you troubleshoot infrastructure regardless of app complexity
- **Simpler**: Less cognitive load, more focus on K8s resources

**API Mock Service:**
- Uses nginx with ConfigMap for JSON responses
- `/health` endpoint returns `{"status":"healthy"}`
- `/` endpoint returns `{"message":"API is running"}`
- No actual database connections needed
- Perfect for testing service mesh, ingress, and pod networking

---

## Previous Work - Step 2 Validation Strategy Clarification (2025-10-07)

### Confirmed Correct Approach: Solution ConfigMaps Use "-missing" Suffix

**Key Understanding:**
- This is a DevOps troubleshooting scenario - broken configs stay broken intentionally
- Solution files provide quick fixes that match what broken deployments expect
- User learns to identify problems and apply correct resources

**Current Setup (CORRECT):**
1. **Broken deployments**: Reference missing ConfigMaps (`api-config-missing`, `nginx-config-missing`)
2. **Solution ConfigMaps**: Create with **same names** (`api-config-missing`, `nginx-config-missing`)
3. **Single-step fix**: User applies ConfigMap, deployment automatically works
4. **Solution deployments**: Also reference `-missing` names for consistency

**Why This Approach:**
- **Realistic**: In production, you often create missing resources that existing configs expect
- **Simple**: One `kubectl apply` command makes pods work
- **Educational**: Teaches ConfigMap troubleshooting without overcomplicating
- **Fast**: Step 2 can be completed quickly, allowing focus on other issues

**Step 2 Verification Requirements (verify-step2.sh):**
- ✅ 2 API pods Running (requires ConfigMap creation)
- ✅ 2 API pods Ready
- ✅ 4 services exist: api-service, frontend-service, postgres-service, redis-cache
- ✅ All services have endpoints
- ✅ api-service selector is `app: api`

**User Must Complete in Step 2:**
1. Create API ConfigMap: `kubectl apply -f /root/k8s-app/configmaps/api-config.yaml`
2. Fix API service selector: `app: backend` → `app: api`
3. Create frontend-service
4. Create postgres-service

After these 4 actions, verify-step2.sh will pass.

---

## Previous Work - Killercoda Compatibility Fixes (2025-10-06)

### Fixed Container Command Compatibility and Verification Scripts

**Major Issues Resolved:**
- **Container command compatibility** - Fixed all commands to use container-native tools
- **Storage class issues** - Updated to use Killercoda's `local-path` storage class
- **Directory structure** - Organized files into proper GitOps structure
- **Verification scripts** - Implemented inline verify scripts in setup.sh

### Changes Made:

#### 1. Container Command Fixes:
- **Replaced wget**: Not available in postgres/nginx containers
- **Replaced nslookup**: Not available in nginx:alpine
- **Solution**: Use `getent hosts` for DNS resolution (available in all alpine images)
- **Database tests**: Use `pg_isready` instead of wget
- **Redis tests**: Use `redis-cli ping` instead of wget

#### 2. Storage Class Updates:
- **Changed from**: `storageClassName: standard` or `fast-ssd-missing`
- **Changed to**: `storageClassName: local-path`
- **Reason**: Killercoda kubernetes-kubeadm-1node backend uses local-path by default
- **Updated files**: step3.md, postgres-pvc-SOLUTION.yaml

#### 3. Directory Structure Reorganization:
- **Before**: Mixed structure with backend/, frontend/, database/
- **After**: Proper Kubernetes structure:
  ```
  /root/k8s-app/
  ├── deployments/     (all deployment YAML files)
  ├── services/        (service definitions)
  ├── storage/         (PVC definitions)
  ├── configmaps/      (ConfigMap definitions)
  ├── ingress/         (ingress definitions)
  └── README.md        (troubleshooting guide)
  ```

#### 4. Solution File Pattern:
- **Created *-SOLUTION.yaml files** for reference
- **api-deployment-SOLUTION.yaml**: Fixed deployment with correct ConfigMap reference
- **postgres-deployment-SOLUTION.yaml**: Fixed image tag, env vars, resources
- **postgres-pvc-SOLUTION.yaml**: Fixed storage class and claim name
- **api-config.yaml**: Prepared nginx configuration for API
- **nginx-config.yaml**: Prepared nginx configuration for frontend

#### 5. Inline Verification Scripts:
- **Problem**: Killercoda not loading separate verify-*.sh files from index.json
- **Solution**: Embed verification scripts directly in setup.sh
- **Implementation**: Added verify-step2 script to /usr/local/bin
- **Script checks**:
  - API pods running (2/2)
  - API pods ready (2/2)
  - All 4 services exist (api-service, frontend-service, postgres-service, redis-cache)
  - All services have endpoints
  - API service selector is correct (app=api)

#### 6. Updated All Step Documentation:
- **Step 2**: Changed to use `getent hosts` for DNS tests
- **Step 3**: Updated storage class to local-path
- **Step 4**: Changed to apply prepared ConfigMap files
- **Step 5**: Fixed all container commands to use native tools

### DevOps Skills Now Tested:
1. ✅ kubectl troubleshooting commands (get, describe, logs, events)
2. ✅ YAML manifest editing and validation
3. ✅ ConfigMap and volume mount understanding
4. ✅ Service selector debugging
5. ✅ PVC and storage class management
6. ✅ Image repository and tag troubleshooting
7. ✅ Resource limits tuning
8. ✅ Ingress configuration
9. ✅ Systematic debugging methodology
10. ✅ Container-native command usage

**No Application Code Required** - Pure DevOps/SRE focus!

---

## Previous Work - DevOps-Focused Kubernetes Troubleshooting (2025-10-06)

### Refactored for Pure DevOps Skills Assessment

**Major Philosophy Change:**
- **Removed all code writing tasks** - DevOps should not write application code
- **Focus on kubectl and YAML** - pure infrastructure/configuration management
- **Prepared hint files** - reference solutions available in /root/k8s-app/ directories

### Changes Made:

#### 1. Setup Script Enhancement:
- **API Container**: Changed to nginx:alpine with missing ConfigMap (api-config-missing)
- **Added hint files**: api-config.yaml, api-deployment-fixed.yaml, nginx-config.yaml
- **ConfigMap approach**: Simple nginx configs instead of Node.js code
- Candidates use `kubectl apply -f` on prepared files or `kubectl edit` to fix

#### 2. Step 2 Redesign (API Pods):
- **Before**: Created Node.js code inline with kubectl create configmap --from-literal
- **After**: Apply prepared nginx ConfigMap from hint file
- **Skills tested**: Understanding ConfigMap references, YAML editing, kubectl apply
- **Options provided**: kubectl edit vs kubectl apply -f approaches

#### 3. Step 4 Simplification (Frontend):
- **Before**: Created ConfigMap with inline YAML heredoc
- **After**: Apply prepared nginx-config.yaml file
- **DevOps focus**: File-based configuration management

#### 4. Updated SOLUTION.md:
- All solutions now use prepared YAML files
- Multiple solution paths documented (kubectl edit vs apply)
- Emphasized DevOps skills over development skills
- Added "Key DevOps Takeaways" section

### DevOps Skills Tested:
1. ✅ kubectl troubleshooting commands (get, describe, logs, events)
2. ✅ YAML manifest editing and validation
3. ✅ ConfigMap and volume mount understanding
4. ✅ Service selector debugging
5. ✅ PVC and storage class management
6. ✅ Image repository and tag troubleshooting
7. ✅ Resource limits tuning
8. ✅ Ingress configuration
9. ✅ Systematic debugging methodology

**No Application Code Required** - Pure DevOps/SRE focus!

---

## Previous Work - Kubernetes Pod Troubleshooting Scenario Updates (2025-10-06)

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