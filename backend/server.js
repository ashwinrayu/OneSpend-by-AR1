import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes.js';
import transactionRoutes from './routes/transactionRoutes.js';
import { initDb } from './config/db.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 10000;

// Security & Parsing Middleware
app.use(helmet());
app.use(cors({
  origin: '*', // Allow Flutter mobile & desktop apps
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Lightweight Health Check Endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    app: 'OneSpend by AR1 API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// Mount API Routes
app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);

// Root Welcome Endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Welcome to OneSpend by AR1 REST API Backend',
    documentation: '/health',
  });
});

// 404 Route Handler
app.use((req, res) => {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
});

// Centralized Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
  });
});

// Start Server and Verify DB
app.listen(PORT, async () => {
  console.log(`🚀 OneSpend by AR1 Backend running on port ${PORT}`);
  console.log(`📡 Health Check available at http://localhost:${PORT}/health`);
  await initDb();
});

export default app;

