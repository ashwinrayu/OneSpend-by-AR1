import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes.js';
import transactionRoutes from './routes/transactionRoutes.js';
import loanRoutes from './routes/loanRoutes.js';
import subscriptionRoutes from './routes/subscriptionRoutes.js';
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
    version: '1.2.5',
    timestamp: new Date().toISOString(),
  });
});

// App Version & In-App Cloud Auto-Updater Endpoint
app.get('/api/app/version', (req, res) => {
  res.status(200).json({
    latestVersion: '1.2.5',
    buildNumber: 11,
    releaseDate: '2026-11-08',
    releaseNotes: '• 🌐 Robust Global Synchronization: Redundant dual-endpoint sync via Vercel Edge CDN and Render Backend with 60s tolerant timeout\n• 🧮 Two-Way Linked Loan & EMI Calculations: Principal, Monthly EMI, Tenure, and Paid Amount calculate accurately without mismatch\n• 🔀 Optional Interest Rate & Details: Interest rate is OFF by default (0% No-Cost EMI); financial institution details are neatly tucked into optional toggle\n• 🔒 Enhanced Sign-Out Privacy: Completely clears session data, metrics, and cached loans/transactions upon signing out\n• ⚡ Independent Domain Sync: Transactions, Loans, and Subscriptions sync concurrently and independently without blocking each other',
    downloadUrl: 'https://github.com/ashwinrayu/OneSpend-by-AR1/releases/download/v1.2.5/app-release.apk',
    webAppUrl: 'https://onespend.vercel.app',
    isMandatory: false
  });
});

// Mount API Routes
app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/loans', loanRoutes);
app.use('/api/subscriptions', subscriptionRoutes);

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

// Start Server on 0.0.0.0 and Verify DB
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 OneSpend by AR1 Backend running on 0.0.0.0:${PORT}`);
  console.log(`📡 Health Check available at http://0.0.0.0:${PORT}/health`);
  try {
    await initDb();
  } catch (dbErr) {
    console.error('⚠️ DB Initialization Notice:', dbErr.message);
  }
});

export default app;

