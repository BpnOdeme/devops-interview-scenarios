const express = require('express');
const mongoose = require('mongoose');
const Joi = require('joi');
const winston = require('winston');
const axios = require('axios');
const amqp = require('amqplib');

const app = express();
const PORT = process.env.PORT || 3003;

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

let rabbitConnection = null;
let rabbitChannel = null;

const connectRabbitMQ = async () => {
  try {
    const url = process.env.RABBITMQ_URL || 'amqp://rabbitmq:5672';
    rabbitConnection = await amqp.connect(url);
    rabbitChannel = await rabbitConnection.createChannel();
    
    await rabbitChannel.assertQueue('order_events', { durable: true });
    await rabbitChannel.assertQueue('inventory_updates', { durable: true });
    
    logger.info('Connected to RabbitMQ');
  } catch (error) {
    logger.error('RabbitMQ connection error:', error);
    setTimeout(connectRabbitMQ, 5000);
  }
};

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URL || 'mongodb://mongodb:27017/orderdb', {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    logger.info('Connected to MongoDB');
  } catch (error) {
    logger.error('MongoDB connection error:', error);
    setTimeout(connectDB, 5000);
  }
};

const orderItemSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  productName: { type: String, required: true },
  quantity: { type: Number, required: true, min: 1 },
  price: { type: Number, required: true, min: 0 },
  subtotal: { type: Number, required: true }
});

const orderSchema = new mongoose.Schema({
  orderNumber: { type: String, required: true, unique: true },
  userId: { type: String, required: true },
  userEmail: { type: String, required: true },
  items: [orderItemSchema],
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'],
    default: 'pending'
  },
  shippingAddress: {
    street: { type: String, required: true },
    city: { type: String, required: true },
    state: String,
    zipCode: { type: String, required: true },
    country: { type: String, required: true }
  },
  paymentMethod: {
    type: String,
    enum: ['credit_card', 'debit_card', 'paypal', 'bank_transfer'],
    required: true
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  subtotal: { type: Number, required: true },
  tax: { type: Number, default: 0 },
  shipping: { type: Number, default: 0 },
  total: { type: Number, required: true },
  notes: String,
  statusHistory: [{
    status: String,
    timestamp: { type: Date, default: Date.now },
    note: String
  }],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Order = mongoose.model('Order', orderSchema);

const validateOrder = (order) => {
  const schema = Joi.object({
    userId: Joi.string().required(),
    userEmail: Joi.string().email().required(),
    items: Joi.array().items(Joi.object({
      productId: Joi.string().required(),
      quantity: Joi.number().min(1).required()
    })).min(1).required(),
    shippingAddress: Joi.object({
      street: Joi.string().required(),
      city: Joi.string().required(),
      state: Joi.string(),
      zipCode: Joi.string().required(),
      country: Joi.string().required()
    }).required(),
    paymentMethod: Joi.string().valid('credit_card', 'debit_card', 'paypal', 'bank_transfer').required(),
    notes: Joi.string()
  });
  return schema.validate(order);
};

const generateOrderNumber = () => {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substr(2, 5);
  return `ORD-${timestamp}-${random}`.toUpperCase();
};

const publishOrderEvent = async (event) => {
  if (rabbitChannel) {
    try {
      await rabbitChannel.sendToQueue(
        'order_events',
        Buffer.from(JSON.stringify(event)),
        { persistent: true }
      );
      logger.info(`Order event published: ${event.type}`);
    } catch (error) {
      logger.error('Error publishing order event:', error);
    }
  }
};

const validateProductAndGetDetails = async (productId) => {
  try {
    const productServiceUrl = process.env.PRODUCT_SERVICE_URL || 'http://product-service:3002';
    const response = await axios.get(`${productServiceUrl}/products/${productId}`);
    return response.data;
  } catch (error) {
    logger.error(`Error fetching product ${productId}:`, error.message);
    return null;
  }
};

const updateProductStock = async (productId, quantity, operation) => {
  try {
    const productServiceUrl = process.env.PRODUCT_SERVICE_URL || 'http://product-service:3002';
    await axios.patch(`${productServiceUrl}/products/${productId}/stock`, {
      quantity,
      operation
    });
    return true;
  } catch (error) {
    logger.error(`Error updating stock for product ${productId}:`, error.message);
    return false;
  }
};

app.post('/orders', async (req, res) => {
  try {
    const { error } = validateOrder(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const orderItems = [];
    let subtotal = 0;

    for (const item of req.body.items) {
      const product = await validateProductAndGetDetails(item.productId);
      if (!product) {
        return res.status(400).json({ error: `Product ${item.productId} not found` });
      }
      if (product.stock < item.quantity) {
        return res.status(400).json({ 
          error: `Insufficient stock for product ${product.name}. Available: ${product.stock}` 
        });
      }

      const itemSubtotal = product.price * item.quantity;
      orderItems.push({
        productId: item.productId,
        productName: product.name,
        quantity: item.quantity,
        price: product.price,
        subtotal: itemSubtotal
      });
      subtotal += itemSubtotal;
    }

    const tax = subtotal * 0.1;
    const shipping = subtotal > 100 ? 0 : 10;
    const total = subtotal + tax + shipping;

    const order = new Order({
      orderNumber: generateOrderNumber(),
      userId: req.body.userId,
      userEmail: req.body.userEmail,
      items: orderItems,
      shippingAddress: req.body.shippingAddress,
      paymentMethod: req.body.paymentMethod,
      subtotal,
      tax,
      shipping,
      total,
      notes: req.body.notes,
      statusHistory: [{ status: 'pending', note: 'Order created' }]
    });

    await order.save();

    for (const item of orderItems) {
      await updateProductStock(item.productId, item.quantity, 'subtract');
    }

    await publishOrderEvent({
      type: 'order_created',
      orderId: order._id,
      orderNumber: order.orderNumber,
      userId: order.userId,
      total: order.total,
      timestamp: new Date()
    });

    logger.info(`Order created: ${order.orderNumber}`);
    res.status(201).json(order);
  } catch (error) {
    logger.error('Error creating order:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/orders', async (req, res) => {
  try {
    const { userId, status, page = 1, limit = 20 } = req.query;
    const query = {};
    
    if (userId) query.userId = userId;
    if (status) query.status = status;

    const skip = (page - 1) * limit;
    
    const orders = await Order.find(query)
      .sort('-createdAt')
      .skip(skip)
      .limit(parseInt(limit));
    
    const total = await Order.countDocuments(query);
    
    res.json({
      orders,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    logger.error('Error fetching orders:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/orders/:id', async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.json(order);
  } catch (error) {
    logger.error('Error fetching order:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.patch('/orders/:id/status', async (req, res) => {
  try {
    const { status, note } = req.body;
    
    if (!status) {
      return res.status(400).json({ error: 'Status is required' });
    }

    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (status === 'cancelled' && order.status !== 'pending' && order.status !== 'confirmed') {
      return res.status(400).json({ error: 'Cannot cancel order in current status' });
    }

    order.status = status;
    order.statusHistory.push({ status, note: note || `Status changed to ${status}` });
    order.updatedAt = new Date();

    if (status === 'cancelled') {
      for (const item of order.items) {
        await updateProductStock(item.productId, item.quantity, 'add');
      }
    }

    await order.save();

    await publishOrderEvent({
      type: 'order_status_updated',
      orderId: order._id,
      orderNumber: order.orderNumber,
      oldStatus: order.status,
      newStatus: status,
      timestamp: new Date()
    });

    logger.info(`Order ${order.orderNumber} status updated to ${status}`);
    res.json(order);
  } catch (error) {
    logger.error('Error updating order status:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.patch('/orders/:id/payment', async (req, res) => {
  try {
    const { paymentStatus } = req.body;
    
    if (!paymentStatus) {
      return res.status(400).json({ error: 'Payment status is required' });
    }

    const validStatuses = ['pending', 'paid', 'failed', 'refunded'];
    if (!validStatuses.includes(paymentStatus)) {
      return res.status(400).json({ error: 'Invalid payment status' });
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { 
        paymentStatus,
        updatedAt: new Date()
      },
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (paymentStatus === 'paid' && order.status === 'pending') {
      order.status = 'confirmed';
      order.statusHistory.push({ status: 'confirmed', note: 'Payment received' });
      await order.save();
    }

    await publishOrderEvent({
      type: 'payment_status_updated',
      orderId: order._id,
      orderNumber: order.orderNumber,
      paymentStatus,
      timestamp: new Date()
    });

    logger.info(`Order ${order.orderNumber} payment status updated to ${paymentStatus}`);
    res.json(order);
  } catch (error) {
    logger.error('Error updating payment status:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/orders/user/:userId', async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.params.userId })
      .sort('-createdAt');
    res.json(orders);
  } catch (error) {
    logger.error('Error fetching user orders:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    service: 'order-service',
    timestamp: new Date().toISOString(),
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    rabbitmq: rabbitConnection ? 'connected' : 'disconnected'
  };
  res.json(health);
});

const startServer = async () => {
  await connectDB();
  await connectRabbitMQ();
  
  app.listen(PORT, () => {
    logger.info(`Order Service running on port ${PORT}`);
  });
};

startServer().catch(err => {
  logger.error('Failed to start server:', err);
  process.exit(1);
});