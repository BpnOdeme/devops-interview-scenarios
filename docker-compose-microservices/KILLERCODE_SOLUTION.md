# Killercode Platform - Docker Compose Troubleshooting Çözümü

## Platform Özeti
Killercode, DevOps adaylarının troubleshooting becerilerini test eden bir eğitim platformudur. Bu senaryoda kasıtlı olarak bozulmuş bir Docker Compose stack'i düzeltmeniz isteniyor.

## DevOps Adayının Sorumluluğu
DevOps adayı **SADECE** infrastructure ve configuration hatalarından sorumludur:
- Docker Compose yapılandırması
- Network configuration
- Port mapping
- Environment variables (docker-compose.yml içinde)
- Volume mounts
- Service dependencies

DevOps adayı application code hatalarından **SORUMLU DEĞİLDİR**.

## Step-by-Step Çözüm

### Step 1: Analyze the Architecture
```bash
cd /root/microservices
chmod 644 docker-compose.yml
cat docker-compose.yml
docker network ls
```

### Step 2: Fix Network Configuration
```bash
# Çakışan network'i sil
docker network rm backend-net 2>/dev/null || true

# docker-compose.yml'de tüm servisleri aynı network'e al
nano docker-compose.yml
```

**Düzeltmeler:**
- Tüm servisleri `app-network` altında topla
- `driver: overlay` → `driver: bridge` (single host için)

### Step 3: Fix Service Dependencies
```bash
nano docker-compose.yml
```

**Environment Variable Düzeltmeleri:**
```yaml
api:
  environment:
    - DB_HOST=db              # database → db
    - DB_PORT=3306            # 3307 → 3306
    - DB_USER=appuser         # EKLE
    - DB_PASSWORD=apppass     # EKLE
    - DB_NAME=appdb           # EKLE
    - REDIS_HOST=cache        # redis-cache → cache
    - REDIS_PORT=6379
    - REDIS_PASSWORD=secretpass  # EKLE
  volumes:
    - ./api:/app              # EKLE - Volume mount
```

**MySQL Düzeltmeleri:**
```yaml
db:
  environment:
    MYSQL_ROOT_PASSWORD: secret
    MYSQL_DATABASE: appdb
    MYSQL_USER: appuser       # EKLE
    MYSQL_PASSWORD: apppass
```

**Redis Port Düzeltmesi:**
```yaml
cache:
  ports:
    - "6379:6379"             # 6379:6380 → 6379:6379
```

**Nginx Proxy Düzeltmesi:**
```bash
nano nginx/default.conf
```
```nginx
location /api {
    proxy_pass http://api:3000;  # api-server:3001 → api:3000
}
```

### Step 4: Test the Stack
```bash
# Dependencies yükle
cd /root/microservices/api && npm install && cd ..

# Stack'i başlat
docker-compose up -d

# Servisleri test et
curl http://localhost:3000/health
curl http://localhost/
curl http://localhost/api

# Database testi
docker-compose exec db mysql -u appuser -papppass -e "SELECT 1;"

# Redis testi
docker-compose exec cache redis-cli -a secretpass ping

# Verification script
./verify-step4.sh
```

## Özet Docker Compose Yapılandırması

```yaml
version: '3.8'

services:
  frontend:
    image: nginx:alpine
    ports:
      - "80:80"
    depends_on:
      - api
    networks:
      - app-network
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    
  api:
    image: node:14-alpine
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_USER=appuser
      - DB_PASSWORD=apppass
      - DB_NAME=appdb
      - REDIS_HOST=cache
      - REDIS_PORT=6379
      - REDIS_PASSWORD=secretpass
    depends_on:
      - db
      - cache
    networks:
      - app-network
    volumes:
      - ./api:/app
    command: sh -c "cd /app && npm install && npm start"
    working_dir: /app
    
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: appdb
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppass
    ports:
      - "3306:3306"
    networks:
      - app-network
    volumes:
      - db-data:/var/lib/mysql
      
  cache:
    image: redis:6-alpine
    ports:
      - "6379:6379"
    networks:
      - app-network
    command: redis-server --requirepass secretpass

networks:
  app-network:
    driver: bridge

volumes:
  db-data:
    driver: local
```

## Önemli Notlar

1. **API Kodu Düzeltildi:**
   - setup.sh içindeki API kodu artık proper fallback değerleri ile yazıldı
   - Environment variable'lar tanımlı olmasa bile default değerler kullanılıyor
   - Retry logic eklendi (MySQL ve Redis için)
   - DevOps adayı artık sadece infrastructure sorunlarına odaklanabilir

2. **DevOps'un Düzeltmesi Gereken Sorunlar:**
   - ✅ File permissions (chmod 644 docker-compose.yml)
   - ✅ Network configuration (tüm servisler aynı network'te)
   - ✅ Service naming (DB_HOST=db, REDIS_HOST=cache)
   - ✅ Port mappings (6379:6379)
   - ✅ Volume mounts (./api:/app eklenmeli)
   - ✅ MySQL user eklenmeli
   - ✅ Network driver (overlay → bridge)
   - ✅ Nginx proxy configuration (api-server:3001 → api:3000)

3. **Best Practices Uygulandı:**
   - Application code proper error handling içeriyor
   - Retry logic ile database bağlantı sorunları handle ediliyor
   - Default değerler ile configuration eksiklikleri tolere ediliyor
   - Graceful shutdown implementasyonu

4. **Killercode Senaryosu İçin:**
   - DevOps adayı artık sadece infrastructure ve configuration sorunlarına odaklanabilir
   - Application code sorunları elimine edildi
   - Tüm testler başarılı olmalı (docker-compose düzeltildikten sonra)

## Test Komutları Özeti
```bash
# Tüm servislerin durumu
docker-compose ps

# Log kontrolü
docker-compose logs -f

# Health check'ler
curl http://localhost:3000/health
curl http://localhost/api

# Database ve cache testleri
docker-compose exec db mysql -u appuser -papppass -e "SELECT 1;"
docker-compose exec cache redis-cli -a secretpass ping
```