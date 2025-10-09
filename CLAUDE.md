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

## Recent Work - Removed Direct kubectl set image Command (2025-10-08)

### Changed from Complete Command to Command Pattern

**User Request:** "kubectl set image deployment/postgres postgres=postgres:15 -n webapp bu komutu bizim vermemiz mantıklı mı? bu bilinmesi gerekmez mi?"

**Problem:** Giving exact command is too easy - just copy-paste the solution

**Changes Made:**

#### step3.md Task 2 - Fix Image Issues (lines 33-55)
**Before (direct solution):**
```bash
# Fix the deployment
kubectl set image deployment/postgres postgres=postgres:15 -n webapp

# Or edit directly
kubectl edit deployment postgres -n webapp
```

**After (pattern-based):**
```bash
# Fix using one of these methods:

# Option 1: Edit deployment interactively
kubectl edit deployment postgres -n webapp
# Find spec.template.spec.containers[].image and update to valid tag

# Option 2: Use set image command
# Syntax: kubectl set image deployment/<name> <container-name>=<new-image> -n <namespace>
# Check container name: kubectl get deployment postgres -n webapp -o jsonpath='{.spec.template.spec.containers[0].name}'

Hint: Verify image tags on Docker Hub before applying
```

**Rationale:**
- `kubectl set image` is a basic kubectl command users should know
- But giving exact syntax with all values is too easy
- Show the command pattern/syntax instead
- Users must fill in: deployment name, container name, image tag
- Forces understanding of command structure

**Impact:**
- ❌ No more copy-paste exact commands
- ✅ Learn kubectl command syntax
- ✅ Understand what each parameter means
- ✅ Apply pattern to other scenarios
- ✅ Verify image availability before deploying

---

## Previous Work - Made Error Names Less Obvious (2025-10-08)

### Changed Obvious Error Indicators to Realistic Values

**User Request:** "postgres-deployment.yaml içerisinde image hatalı olduğu açık ortada wrong yerine başka bir ifade koyalım ilk bakışta düzeltileceği anlaşılmasın pvc claimName de aynı şekilde"

**Problem:** Current naming was too obvious:
- `postgres:13-wrong` → Screams "I'm broken!"
- `postgres-pvc-wrong` → Obviously wrong

**Changes Made:**

#### 1. Postgres Image Tag (setup.sh line 43)
**Before:**
```yaml
image: postgres:13-wrong
```

**After:**
```yaml
image: postgres:13-alpine
```

**Rationale:**
- Looks like a real tag
- Not obviously wrong at first glance
- Will still cause ImagePullBackOff (tag doesn't exist)
- Users must read error message to understand issue

#### 2. PVC Claim Name (setup.sh line 62)
**Before:**
```yaml
persistentVolumeClaim:
  claimName: postgres-pvc-wrong
```

**After:**
```yaml
persistentVolumeClaim:
  claimName: postgres-data
```

**Rationale:**
- Logical, descriptive name
- Looks intentional, not broken
- Will cause mounting error (PVC doesn't exist)
- Users must compare with actual PVC name

#### 3. Updated SOLUTION.md References
- Updated all `postgres:13-wrong` → `postgres:13-alpine`
- Updated all `postgres-pvc-wrong` → `postgres-data`
- Maintains accuracy in solution guide

**Files Modified:**
- setup.sh: Lines 43, 62
- SOLUTION.md: Lines 113, 121, 162, 168, 392, 426

**Impact:**
- ❌ No more `-wrong` suffixes giving it away
- ✅ Errors look like real mistakes
- ✅ Must investigate error messages
- ✅ Can't just search for "wrong"
- ✅ More realistic troubleshooting

---

## Previous Work - Removed Direct YAML Solutions from Step Guides (2025-10-08)

### Converted Step Instructions to Pattern-Based Learning

**User Request:** "step 2 de 4. Fix Service Selectors, 5. Create Missing Services adımlarında bu şekilde açık bilgilerle ilerlemeli miyiz? yoksa sadece nasıl bir servis tanımına ihtiyaç olduğunu şu uygulama şu portta çalışır gibi mi yapalım"

**Decision:** Pattern-based learning - show the pattern, not the complete solution

**Changes Made:**

#### 1. step2.md - Removed Ready-to-Use Service YAMLs
**Before (too easy):**
```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: webapp
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

**After (pattern-based):**
```markdown
The application architecture requires:
- API service: exposes port 3000
- Frontend service: exposes port 80
- Database service: exposes port 5432

If services are missing, create them with:
- Correct selector matching pod labels
- Appropriate port and targetPort
- type: ClusterIP

Example pattern:
kubectl create service clusterip <service-name> --tcp=<port>:<targetPort>
```

#### 2. step3.md - Removed Complete PVC YAML
**Before:**
```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
EOF
```

**After:**
```markdown
Create new PVC with correct storage class
Use kubectl apply with a PVC manifest that includes:
- accessModes: ReadWriteOnce
- storageClassName: <available-storage-class>
- storage: 1Gi

Hints:
- Check available storage classes: kubectl get storageclass
- Common storage classes: local-path, standard, hostpath
```

#### 3. step3.md - Genericized Environment Variables
**Before:**
```bash
kubectl set env deployment/postgres -n webapp \
  POSTGRES_USER=webapp_user \
  POSTGRES_PASSWORD=webapp_pass \
  POSTGRES_DB=webapp
```

**After:**
```bash
PostgreSQL requires these environment variables:
- POSTGRES_USER: Database user
- POSTGRES_PASSWORD: Database password
- POSTGRES_DB: Database name

kubectl set env deployment/postgres -n webapp \
  POSTGRES_USER=<user> \
  POSTGRES_PASSWORD=<password> \
  POSTGRES_DB=<database-name>
```

**Files Modified:**
- step2.md: Tasks 4-5 converted to pattern-based (lines 77-129)
- step3.md: PVC creation and env vars genericized (lines 73-140)

**Impact:**
- ❌ No more copy-paste YAML solutions
- ✅ Learn the pattern and apply it
- ✅ Understand requirements (ports, selectors, env vars)
- ✅ Think about what values to use
- ✅ More realistic DevOps work

---

## Previous Work - Removed SOLUTION.yaml Files and Obvious Hints (2025-10-08)

### Further Reduced Hint Level for More Realistic Troubleshooting

**User Request:** "SOLUTION.yaml dosyaları da hala bulunmakta ve Step1 Expected Findings kısmı öyle mi kalsın?"

**Changes Made:**

#### 1. Removed All SOLUTION.yaml File Generation
**Before:**
```bash
# setup.sh created these files:
- postgres-pvc-SOLUTION.yaml
- postgres-deployment-SOLUTION.yaml
- api-deployment-SOLUTION.yaml
```

**After:**
```bash
# Only ConfigMaps remain (needed for pod startup):
- api-config.yaml (needed in Step 2)
- nginx-config.yaml (needed in Step 4)
```

**Rationale:** SOLUTION.yaml files with comments like "# Fixed: Added user" gave away the answers. Users should fix issues using `kubectl edit` or `kubectl set` commands.

#### 2. Updated step1.md Expected Findings to Remove Specifics
**Before (too detailed):**
```markdown
Expected Findings:
- Frontend pod: ContainerCreating - references non-existent ConfigMap (nginx-config-missing)
- Postgres pod: Pending - wrong image tag (postgres:13-wrong) and missing PVC
- API pods: ContainerCreating - missing ConfigMap (api-config-missing) and wrong port
```

**After (investigation-focused):**
```markdown
Expected Findings:
After investigation, you should identify:
- Multiple pods are not in Running state
- Various error states (ContainerCreating, ImagePullBackOff, Pending)
- One pod (Redis) is healthy - use it as a reference
- Issues may be related to:
  - Missing resources (ConfigMaps, PVCs)
  - Wrong image tags
  - Configuration errors
```

**Rationale:** Don't tell them what's wrong - make them use `kubectl describe` and read error messages!

#### 3. Updated setup.sh README Section
**Before:**
```markdown
## Known Issues to Fix
1. PostgreSQL: Wrong image tag, missing env vars, low resources, missing PVC
2. API: Missing ConfigMap, wrong container port, low resource limits, old image
```

**After:**
```markdown
## Your Mission
Investigate and fix issues with:
1. Pods: Multiple pods not running - use kubectl describe to find why
2. Services: Check if endpoints are being created properly
3. Storage: Verify PVC and storage class configuration
```

**Files Modified:**
- setup.sh: Removed SOLUTION.yaml generation (lines 300-402 → single comment)
- setup.sh: Updated README section to be less specific
- step1.md: Made Expected Findings generic (lines 58-69)

**Impact:**
- ❌ No more ready-to-apply SOLUTION files
- ❌ No more "here's exactly what's broken" lists
- ✅ Must investigate with kubectl commands
- ✅ Must read error messages and understand them
- ✅ More realistic troubleshooting experience

---

## Previous Work - Converted to Medium Difficulty (Interview Level) (2025-10-08)

### Removed Obvious Hints for Real DevOps Troubleshooting Experience

**User Request:** "bu devops case'inde ip uçları ve çözümleri ne ölçüde paylaşmalıyız? config-missing image..-wrong tarzı çok kolay hale getirmez mi?"

**Decision:** Orta Seviye (İş Görüşmesi seviyesi)

**Changes Made:**

#### 1. Removed All "BROKEN" Comments from setup.sh
**Before:**
```yaml
image: postgres:13-wrong  # BROKEN: Wrong image tag
selector:
  app: backend  # BROKEN: Wrong selector - should be 'api'
name: api-config-missing  # BROKEN: ConfigMap doesn't exist
```

**After:**
```yaml
image: postgres:13-wrong
selector:
  app: backend
name: api-config
```

**Rationale:** Real production issues don't have comments explaining what's wrong!

#### 2. Changed ConfigMap Naming from "*-missing" to Normal Names
**Before:**
- `api-config-missing` → Too obvious
- `nginx-config-missing` → Screams "I'm missing!"

**After:**
- `api-config` → Normal name, investigate to find it doesn't exist
- `nginx-config` → Normal name

**Impact:** DevOps must use `kubectl describe pod` and read error messages to find missing ConfigMaps.

#### 3. Rewrote All Step Guides to be Investigation-Focused

**step2.md** - Before (too easy):
```markdown
### Fix API Pods
**Issues found:**
1. ConfigMap `api-config-missing` doesn't exist
2. Container port is wrong: `80` → should be `3000`
3. Resources too low: need more memory
4. Image is old version: should be nginx:alpine

**Fix:**
kubectl apply -f /root/k8s-app/configmaps/api-config.yaml
```

**step2.md** - After (investigation-focused):
```markdown
### 1. Investigate API Pod Issues
The API pods are not running. Find out why:

# Check API pod status
kubectl describe pod -l app=api -n webapp

**Common investigation steps:**
- Is there a missing ConfigMap?
- Are there volume mount errors?
- Check what ConfigMaps exist

**Hint:** Look in `/root/k8s-app/configmaps/` for solution files.
```

**step3.md** - Changed to investigation workflow:
- Don't tell them image is wrong → make them check with `kubectl get deployment`
- Don't tell them PVC name is wrong → make them compare with `kubectl describe`
- Provide investigation commands, not direct answers

**step4.md** - Changed to problem-solving approach:
- Don't say "ConfigMap nginx-config-missing doesn't exist" → say "Frontend pod not starting, investigate why"
- Make them use `kubectl describe pod` to find the issue
- Hints instead of answers

#### 4. Key Benefits of Medium Difficulty:
- ✅ **Tests kubectl skills**: Must use describe, logs, get, events
- ✅ **Tests troubleshooting ability**: Can't just follow instructions blindly
- ✅ **Realistic scenarios**: Mirrors actual production debugging
- ✅ **Interview appropriate**: 30-45 minutes, tests DevOps fundamentals
- ✅ **Still guided**: Solution files available, hints provided

#### 5. What Stayed the Same:
- ✅ Solution YAML files still in `/root/k8s-app/` (prepared but not applied)
- ✅ Verification scripts still work
- ✅ Step-by-step structure maintained
- ✅ SOLUTION.md still has detailed answers for review

**Files Modified:**
- setup.sh: Removed all `# BROKEN` comments, changed `-missing`/`-wrong` naming
- step2.md: Completely rewritten to investigation-focused (120 lines → 184 lines)
- step3.md: Rewritten to problem-solving approach (170 lines → 202 lines)
- step4.md: Updated to investigation workflow
- CLAUDE.md: Documented all changes

**Comparison - Difficulty Levels:**

| Aspect | Easy (Before) | Medium (Now) | Hardcore |
|--------|---------------|--------------|----------|
| Naming | `config-missing` | `api-config` | `api-config` |
| Comments | `# BROKEN` | None | None |
| Steps | Direct fixes | Investigation + hints | No hints |
| YAML files | Ready with comments | Ready, no comments | Must write yourself |
| Time | 15-20 min | 30-45 min | 60-90 min |

---

## Previous Work - Replaced Minikube Commands with Kubeadm NodePort Access (2025-10-08)

### Updated Step 4 and Step 5 for Kubeadm Clusters

**Problem:**
- Step 4 and Step 5 had minikube-specific commands (`minikube ip`)
- Killercoda uses kubeadm cluster, not minikube
- Need to use NodePort to access ingress controller

**Root Cause:**
- `minikube ip` doesn't exist in kubeadm clusters
- Ingress controller exposed via NodePort service in kubeadm
- Need to get node IP and NodePort to access ingress

**Solution:**
Replaced all minikube commands with kubeadm-compatible commands:

```bash
# Old (minikube):
curl -H "Host: webapp.local" http://$(minikube ip)/

# New (kubeadm with NodePort):
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl -H "Host: webapp.local" http://$NODE_IP:$INGRESS_PORT/
```

**Changes Made:**
1. **step4.md**:
   - Removed `minikube addons` references
   - Updated Task 6 (Test External Access) with NodePort approach
   - Updated Task 7 (Add Host Entry) with node IP
   - Updated Verification Commands section

2. **step5.md**:
   - Updated Task 3 (Test Complete Application Stack)
   - Updated Section 6 (Final Health Check)
   - Updated Final Verification script

**Files Modified:**
- kubernetes-pod-troubleshooting/step4.md (lines 13, 172-203, 220-226)
- kubernetes-pod-troubleshooting/step5.md (lines 63-73, 198-206, 240-242)

**User Request:** "step4 de minikube ile çalışmıyoruz kubeadm bulunmakta"

---

## Previous Work - Fixed Step 2 Verification to Only Check API Endpoints (2025-10-08)

### Updated Step 2 Verify Script and Expected Results

**Problem:**
- Step 2 verify script checked ALL services for endpoints (including frontend)
- Frontend pod is ContainerCreating until Step 4 (needs ConfigMap)
- Verify script failed because frontend-service had `<none>` endpoints
- Expected Results incorrectly stated "All services should have valid endpoints"

**Root Cause:**
```bash
# Wrong approach - checking all services:
for service in "${REQUIRED_SERVICES[@]}"; do
    # This checked frontend-service too!
    ENDPOINTS=$(kubectl get endpoints $service ...)
    if [ -z "$ENDPOINTS" ]; then
        ((MISSING_SERVICES++))  # FAIL on frontend
    fi
done
```

**Solution:**
1. **verify-step2.sh**: Only check api-service endpoints
2. **setup.sh line 525-546**: Updated inline verify script
3. **step2.md Expected Results**: Clarified which services will have endpoints

**Changes:**
```bash
# New approach - only check API endpoints:
for service in "${REQUIRED_SERVICES[@]}"; do
    if kubectl get svc $service -n webapp >/dev/null 2>&1; then
        echo "✅ Service $service exists"
    fi
done

# Only check API service endpoints (frontend fixed in Step 4)
ENDPOINTS=$(kubectl get endpoints api-service -n webapp ...)
```

**Updated Expected Results:**
- ✅ API service should have endpoints (2 pod IPs)
- ✅ postgres-service and redis-cache should have endpoints
- ⚠️ **frontend-service will have NO endpoints** (ConfigMap created in Step 4)

**User Question:** "step 2 check edildiğinde frontend servisinin endpoint'i olup olmadığına bakılacak mı?"
**Answer:** Hayır, artık sadece API endpoint kontrolü yapılıyor.

---

## Previous Work - Enhanced Lab with Log Analysis and Real Node.js API (2025-10-07)

### Added DevOps Skills: Log Analysis and Application Troubleshooting

**Changes Made:**

#### 1. Created Real Node.js API Application (api-app/):
- **server.js**: Express API with PostgreSQL and Redis connectivity
- **package.json**: Dependencies (express, pg, redis)
- **Dockerfile**: Container image definition
- Endpoints: `/health`, `/`, `/users`, `/cache/test`
- Ready for future use when we want real DB/Redis testing

**Note**: Currently using nginx mock API for simplicity, but real Node.js app is prepared.

#### 2. Updated intro.md:
- Corrected component descriptions (was saying "Node.js API", now says "Mock API")
- Fixed directory structure (removed wrong paths like `/root/k8s-app/frontend/`)
- Updated to match actual folder structure (deployments/, services/, storage/, configmaps/)
- Added success criteria with specific checks
- Clarified focus on Kubernetes infrastructure, not app development

#### 3. Enhanced Step 5 with Log Analysis:
Added comprehensive DevOps troubleshooting section:

**Section 4: Analyze Pod Logs**
- How to check API logs for startup issues
- How to check PostgreSQL logs for connection errors
- How to check Redis logs for memory issues
- How to check Frontend logs for nginx config
- How to find error events with kubectl

**Section 5: Verify Database and Cache Connectivity**
- PostgreSQL connection test with psql
- Redis ping test
- Redis SET/GET test
- Clear expected outputs and error meanings

**Why This Matters:**
- DevOps engineers MUST check logs to verify applications
- Teaches systematic troubleshooting approach
- Shows how to identify common issues (OOM, authentication failures, config errors)
- Real-world skill: reading logs is critical for production support

**Examples Added:**
```bash
# PostgreSQL logs - what to look for:
✅ "database system is ready to accept connections"
❌ "FATAL: password authentication failed"
❌ "out of memory"

# Redis logs - what to look for:
✅ "Ready to accept connections"
❌ "OOM" or "out of memory"
```

---

## Previous Work - Fixed API Ready Count Bug in Verify Script (2025-10-07)

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