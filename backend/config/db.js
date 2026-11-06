import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

// Parse PostgreSQL NUMERIC (OID 1700) as JavaScript float instead of string
pg.types.setTypeParser(1700, (val) => (val === null ? null : parseFloat(val)));

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.warn('⚠️ WARNING: DATABASE_URL is not defined in environment variables. Database queries will fail.');
} else if (connectionString.includes('.supabase.co') && !connectionString.includes('pooler.supabase.com')) {
  console.warn('⚠️ WARNING: You are using Supabase Direct Connection URL (db.xxx.supabase.co:5432) which resolves to IPv6.');
  console.warn('   Render free tier does not support IPv6 outbound routing (ENETUNREACH).');
  console.warn('   Please switch to the Supabase Connection Pooler URL (aws-0-[region].pooler.supabase.com:6543).');
}

export const pool = new Pool({
  connectionString,
  ssl: {
    rejectUnauthorized: false,
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client:', err);
});

export const query = (text, params) => pool.query(text, params);

// Auto-initialize tables if not already created
export const initDb = async () => {
  if (!connectionString) return;
  try {
    const client = await pool.connect();
    try {
      await client.query(`
        CREATE EXTENSION IF NOT EXISTS "pgcrypto";

        CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            full_name VARCHAR(255),
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS transactions (
            id VARCHAR(100) PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            title VARCHAR(255) NOT NULL,
            amount NUMERIC(12, 2) NOT NULL,
            type VARCHAR(20) NOT NULL,
            category VARCHAR(100) NOT NULL,
            payment_method VARCHAR(50) NOT NULL,
            timestamp TIMESTAMPTZ NOT NULL,
            notes TEXT,
            is_deleted BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
        CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(user_id, timestamp DESC);
        CREATE INDEX IF NOT EXISTS idx_transactions_updated ON transactions(user_id, updated_at DESC);
      `);
      console.log('✅ PostgreSQL database schema verified and initialized.');
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('Database connection / initialization notice:', err.message);
  }
};

