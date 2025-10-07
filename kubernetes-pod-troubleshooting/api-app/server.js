const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 3000;

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://webapp_user:webapp_password@postgres-service:5432/webapp',
  max: 5,
  connectionTimeoutMillis: 5000,
});

// Redis connection
let redisClient;
const REDIS_URL = process.env.REDIS_URL || 'redis://redis-cache:6379';

async function connectRedis() {
  try {
    redisClient = redis.createClient({
      url: REDIS_URL,
      socket: {
        reconnectStrategy: (retries) => {
          if (retries > 10) {
            console.log('❌ Redis: Too many retry attempts. Giving up.');
            return new Error('Too many retries');
          }
          return retries * 100; // Retry after 100ms * retries
        }
      }
    });

    redisClient.on('error', (err) => {
      console.log('❌ Redis Client Error:', err.message);
    });

    redisClient.on('connect', () => {
      console.log('✅ Redis: Connected successfully');
    });

    await redisClient.connect();
  } catch (err) {
    console.log('❌ Redis: Initial connection failed:', err.message);
  }
}

// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {}
  };

  // Check database
  try {
    await pool.query('SELECT 1');
    health.services.database = 'connected';
  } catch (err) {
    health.services.database = `error: ${err.message}`;
    health.status = 'degraded';
  }

  // Check Redis
  try {
    if (redisClient && redisClient.isOpen) {
      await redisClient.ping();
      health.services.redis = 'connected';
    } else {
      health.services.redis = 'disconnected';
      health.status = 'degraded';
    }
  } catch (err) {
    health.services.redis = `error: ${err.message}`;
    health.status = 'degraded';
  }

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'API is running',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      users: '/users',
      cache: '/cache/test'
    }
  });
});

// Users endpoint - interacts with database
app.get('/users', async (req, res) => {
  try {
    console.log('📊 Fetching users from database...');
    const result = await pool.query('SELECT COUNT(*) as count FROM pg_database');
    res.json({
      message: 'Database query successful',
      databases: result.rows[0].count,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('❌ Database error:', err.message);
    res.status(500).json({
      error: 'Database query failed',
      message: err.message
    });
  }
});

// Cache test endpoint - interacts with Redis
app.get('/cache/test', async (req, res) => {
  try {
    if (!redisClient || !redisClient.isOpen) {
      throw new Error('Redis client not connected');
    }

    console.log('📦 Testing Redis cache...');
    const key = 'test:timestamp';
    const value = new Date().toISOString();

    await redisClient.set(key, value, { EX: 60 });
    const retrieved = await redisClient.get(key);

    res.json({
      message: 'Cache test successful',
      stored: value,
      retrieved: retrieved,
      match: value === retrieved
    });
  } catch (err) {
    console.error('❌ Redis error:', err.message);
    res.status(500).json({
      error: 'Cache test failed',
      message: err.message
    });
  }
});

// Startup
async function startServer() {
  console.log('🚀 Starting API server...');
  console.log(`📍 Port: ${PORT}`);
  console.log(`🗄️  Database: ${process.env.DATABASE_URL || 'postgresql://webapp_user:***@postgres-service:5432/webapp'}`);
  console.log(`📦 Redis: ${REDIS_URL}`);

  // Connect to Redis
  await connectRedis();

  // Test database connection
  try {
    await pool.query('SELECT NOW()');
    console.log('✅ Database: Connected successfully');
  } catch (err) {
    console.log('❌ Database: Initial connection failed:', err.message);
    console.log('⚠️  API will start but database endpoints may not work');
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ API server listening on port ${PORT}`);
  });
}

startServer().catch(err => {
  console.error('❌ Failed to start server:', err);
  process.exit(1);
});
