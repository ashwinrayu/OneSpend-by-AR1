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
    version: '1.0.2',
    timestamp: new Date().toISOString(),
  });
});

// App Version & In-App Cloud Auto-Updater Endpoint
app.get('/api/app/version', (req, res) => {
  res.status(200).json({
    latestVersion: '1.2.4',
    buildNumber: 10,
    releaseDate: '2026-11-08',
    releaseNotes: '• 🧮 Two-Way Linked Loan & EMI Calculations: Principal, Monthly EMI, Tenure, and Paid Amount calculate accurately without mismatch\n• 🔀 Optional Interest Rate & Details: Interest rate is OFF by default (0% No-Cost EMI); financial institution details are neatly tucked into optional toggle\n• 🔒 Enhanced Sign-Out Privacy: Completely clears session data, metrics, and cached loans/transactions upon signing out\n• ⚡ Instant Live Cloud Sync: Enhanced real-time synchronization between Android APK and Web with focus-triggered updates',
    downloadUrl: 'https://github.com/ashwinrayu/OneSpend-by-AR1/releases/download/v1.2.4/app-release.apk',
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

// Start Server and Verify DB
app.listen(PORT, async () => {
  console.log(`🚀 OneSpend by AR1 Backend running on port ${PORT}`);
  console.log(`📡 Health Check available at http://localhost:${PORT}/health`);
  await initDb();
});

export default app;

