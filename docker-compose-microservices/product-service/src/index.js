const express = require('express');
const mongoose = require('mongoose');
const Joi = require('joi');
const winston = require('winston');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 3002;

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

app.use(express.json());

const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://redis:6379'
});

redisClient.on('error', err => logger.error('Redis Client Error', err));
redisClient.on('connect', () => logger.info('Connected to Redis'));

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URL || 'mongodb://mongodb:27017/productdb', {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    logger.info('Connected to MongoDB');
  } catch (error) {
    logger.error('MongoDB connection error:', error);
    setTimeout(connectDB, 5000);
  }
};

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true, min: 0 },
  category: { type: String, required: true },
  sku: { type: String, required: true, unique: true },
  stock: { type: Number, default: 0, min: 0 },
  images: [String],
  attributes: {
    brand: String,
    weight: Number,
    dimensions: {
      length: Number,
      width: Number,
      height: Number
    }
  },
  ratings: {
    average: { type: Number, default: 0, min: 0, max: 5 },
    count: { type: Number, default: 0 }
  },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

productSchema.index({ name: 'text', description: 'text' });
productSchema.index({ category: 1, price: 1 });

const Product = mongoose.model('Product', productSchema);

const validateProduct = (product) => {
  const schema = Joi.object({
    name: Joi.string().min(3).max(200).required(),
    description: Joi.string().min(10).required(),
    price: Joi.number().min(0).required(),
    category: Joi.string().required(),
    sku: Joi.string().required(),
    stock: Joi.number().min(0),
    images: Joi.array().items(Joi.string()),
    attributes: Joi.object({
      brand: Joi.string(),
      weight: Joi.number(),
      dimensions: Joi.object({
        length: Joi.number(),
        width: Joi.number(),
        height: Joi.number()
      })
    }),
    isActive: Joi.boolean()
  });
  return schema.validate(product);
};

const cacheProduct = async (productId, product) => {
  if (redisClient.isOpen) {
    await redisClient.setEx(
      `product:${productId}`,
      300,
      JSON.stringify(product)
    );
  }
};

const getCachedProduct = async (productId) => {
  if (redisClient.isOpen) {
    const cached = await redisClient.get(`product:${productId}`);
    if (cached) return JSON.parse(cached);
  }
  return null;
};

app.post('/products', async (req, res) => {
  try {
    const { error } = validateProduct(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const existingProduct = await Product.findOne({ sku: req.body.sku });
    if (existingProduct) {
      return res.status(409).json({ error: 'Product with this SKU already exists' });
    }

    const product = new Product(req.body);
    await product.save();
    
    await cacheProduct(product._id, product);
    logger.info(`New product created: ${product.name} (${product.sku})`);
    
    res.status(201).json(product);
  } catch (error) {
    logger.error('Error creating product:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/products', async (req, res) => {
  try {
    const { 
      category, 
      minPrice, 
      maxPrice, 
      search, 
      page = 1, 
      limit = 20,
      sort = '-createdAt'
    } = req.query;

    const query = { isActive: true };
    
    if (category) query.category = category;
    if (minPrice || maxPrice) {
      query.price = {};
      if (minPrice) query.price.$gte = parseFloat(minPrice);
      if (maxPrice) query.price.$lte = parseFloat(maxPrice);
    }
    if (search) {
      query.$text = { $search: search };
    }

    const skip = (page - 1) * limit;
    
    const products = await Product.find(query)
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit));
    
    const total = await Product.countDocuments(query);
    
    res.json({
      products,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    logger.error('Error fetching products:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/products/:id', async (req, res) => {
  try {
    const cached = await getCachedProduct(req.params.id);
    if (cached) {
      logger.info(`Product served from cache: ${req.params.id}`);
      return res.json(cached);
    }

    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    await cacheProduct(product._id, product);
    res.json(product);
  } catch (error) {
    logger.error('Error fetching product:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/products/:id', async (req, res) => {
  try {
    const { error } = validateProduct(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedAt: new Date() },
      { new: true, runValidators: true }
    );

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    if (redisClient.isOpen) {
      await redisClient.del(`product:${product._id}`);
    }

    logger.info(`Product updated: ${product.name} (${product.sku})`);
    res.json(product);
  } catch (error) {
    logger.error('Error updating product:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.patch('/products/:id/stock', async (req, res) => {
  try {
    const { quantity, operation } = req.body;
    
    if (!quantity || !operation) {
      return res.status(400).json({ error: 'Quantity and operation are required' });
    }

    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    if (operation === 'add') {
      product.stock += quantity;
    } else if (operation === 'subtract') {
      if (product.stock < quantity) {
        return res.status(400).json({ error: 'Insufficient stock' });
      }
      product.stock -= quantity;
    } else {
      return res.status(400).json({ error: 'Invalid operation. Use "add" or "subtract"' });
    }

    await product.save();
    
    if (redisClient.isOpen) {
      await redisClient.del(`product:${product._id}`);
    }

    logger.info(`Stock updated for ${product.name}: ${operation} ${quantity}`);
    res.json({ 
      message: 'Stock updated successfully',
      product: {
        id: product._id,
        name: product.name,
        stock: product.stock
      }
    });
  } catch (error) {
    logger.error('Error updating stock:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/products/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { isActive: false, updatedAt: new Date() },
      { new: true }
    );

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    if (redisClient.isOpen) {
      await redisClient.del(`product:${product._id}`);
    }

    logger.info(`Product deactivated: ${product.name} (${product.sku})`);
    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    logger.error('Error deleting product:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/categories', async (req, res) => {
  try {
    const categories = await Product.distinct('category', { isActive: true });
    res.json(categories);
  } catch (error) {
    logger.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    service: 'product-service',
    timestamp: new Date().toISOString(),
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    redis: redisClient.isOpen ? 'connected' : 'disconnected'
  };
  res.json(health);
});

const startServer = async () => {
  await connectDB();
  await redisClient.connect();
  
  app.listen(PORT, () => {
    logger.info(`Product Service running on port ${PORT}`);
  });
};

startServer().catch(err => {
  logger.error('Failed to start server:', err);
  process.exit(1);
});