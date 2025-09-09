const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { createProxyMiddleware } = require('http-proxy-middleware');
const winston = require('winston');

const app = express();
const PORT = process.env.PORT || 3000;

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests from this IP'
});

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(limiter);

app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path} - ${req.ip}`);
  next();
});

const services = {
  users: {
    target: process.env.USER_SERVICE_URL || 'http://user-service:3001',
    changeOrigin: true,
    pathRewrite: {
      '^/api/users': ''
    },
    onError: (err, req, res) => {
      logger.error(`User service error: ${err.message}`);
      res.status(503).json({ error: 'User service unavailable' });
    }
  },
  products: {
    target: process.env.PRODUCT_SERVICE_URL || 'http://product-service:3002',
    changeOrigin: true,
    pathRewrite: {
      '^/api/products': ''
    },
    onError: (err, req, res) => {
      logger.error(`Product service error: ${err.message}`);
      res.status(503).json({ error: 'Product service unavailable' });
    }
  },
  orders: {
    target: process.env.ORDER_SERVICE_URL || 'http://order-service:3003',
    changeOrigin: true,
    pathRewrite: {
      '^/api/orders': ''
    },
    onError: (err, req, res) => {
      logger.error(`Order service error: ${err.message}`);
      res.status(503).json({ error: 'Order service unavailable' });
    }
  }
};

Object.keys(services).forEach(path => {
  app.use(`/api/${path}`, createProxyMiddleware(services[path]));
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'api-gateway',
    timestamp: new Date().toISOString() 
  });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.use((err, req, res, next) => {
  logger.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  logger.info(`API Gateway running on port ${PORT}`);
  logger.info('Available routes:');
  logger.info('  - /api/users -> User Service');
  logger.info('  - /api/products -> Product Service');
  logger.info('  - /api/orders -> Order Service');
  logger.info('  - /health -> Health check');
});