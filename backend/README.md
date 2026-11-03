# OneSpend by AR1 — Express REST API Backend

A production-ready Node.js Express REST API backend for **OneSpend by AR1** connecting to PostgreSQL on **Supabase** via `DATABASE_URL`.

---

## 🚀 Tech Stack
- **Runtime**: Node.js (`"type": "module"`)
- **Framework**: Express.js
- **Database**: PostgreSQL on Supabase (`pg.Pool` with SSL)
- **Authentication**: JWT (`jsonwebtoken`) & password hashing (`bcryptjs`)
- **Security**: Helmet, CORS, parameterized SQL queries

---

## 📂 Project Structure

```text
backend/
├── config/
│   └── db.js                 # PostgreSQL Pool connection with SSL
├── controllers/
│   ├── authController.js     # Register, Login, Me handlers
│   └── transactionController.js # CRUD & Batch Delta-Sync handlers
├── middleware/
│   └── auth.js               # JWT Bearer token authentication
├── routes/
│   ├── authRoutes.js         # /api/auth routes
│   └── transactionRoutes.js  # /api/transactions routes
├── schema.sql                # PostgreSQL table definitions
├── server.js                 # App entry point & health check
├── package.json
└── .env.example
```

---

## 🛠️ Environment Variables Setup

Create a `.env` file in `backend/`:

```env
PORT=10000
NODE_ENV=production

# Supabase PostgreSQL Connection String:
DATABASE_URL=postgresql://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-region.pooler.supabase.com:6543/postgres

# JWT Secret
JWT_SECRET=onespend_production_secret_key_2026
JWT_EXPIRES_IN=30d
```

> **Supabase Tip**: In your Supabase Dashboard, go to **Settings** -> **Database** -> **Connection string** (URI mode with pooling or direct).

---

## 📦 Installation & Running

```bash
cd backend
npm install
npm start
```

For development with hot reload:
```bash
npm run dev
```

---

## 📡 API Endpoints

### 1. System Health
- **`GET /health`**
  - Response: `{"status": "ok", "app": "OneSpend by AR1 API", "version": "1.0.0"}`

---

### 2. Authentication (`/api/auth`)

#### `POST /api/auth/register`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "strongPassword123",
    "full_name": "Ashwin"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "message": "Account registered successfully.",
    "token": "eyJhbGciOi...",
    "user": {
      "id": "uuid-...",
      "email": "user@example.com",
      "full_name": "Ashwin",
      "created_at": "2026-11-03T16:00:00.000Z"
    }
  }
  ```

#### `POST /api/auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "strongPassword123"
  }
  ```
- **Response `200 OK`**: Returns JWT `token` and `user` object.

#### `GET /api/auth/me` *(Protected: Bearer Token)*
- **Header**: `Authorization: Bearer <JWT_TOKEN>`
- **Response `200 OK`**: Returns current authenticated user profile.

---

### 3. Transactions (`/api/transactions`) *(All Protected)*

#### `GET /api/transactions`
- Optional Query Params: `category`, `type` (`expense`/`income`), `startDate`, `endDate`, `limit`, `offset`.
- **Response `200 OK`**:
  ```json
  {
    "count": 2,
    "transactions": [
      {
        "id": "tx_1",
        "title": "Grocery Shopping",
        "amount": "65.00",
        "type": "expense",
        "category": "Food",
        "payment_method": "UPI",
        "timestamp": "2026-11-03T10:15:00.000Z",
        "notes": "Weekly fruits & staples"
      }
    ]
  }
  ```

#### `POST /api/transactions`
- **Request Body**:
  ```json
  {
    "id": "tx_client_uuid_123",
    "title": "Monthly Salary",
    "amount": 75000.00,
    "type": "income",
    "category": "Salary",
    "payment_method": "Bank",
    "timestamp": "2026-11-01T10:00:00.000Z",
    "notes": "Base salary deposit"
  }
  ```
- **Response `201 Created`**

#### `PUT /api/transactions/:id`
- Updates fields (`title`, `amount`, `category`, `notes`, etc.) for `req.userId`.

#### `DELETE /api/transactions/:id`
- Soft-deletes transaction record ensuring offline delta-sync consistency.

#### `POST /api/transactions/sync` *(Batch Delta-Sync)*
- Designed for offline-first Flutter desktop/mobile sync:
- **Request Body**:
  ```json
  {
    "lastSyncedAt": "2026-11-01T00:00:00.000Z",
    "clientChanges": [
      {
        "id": "tx_offline_1",
        "title": "Coffee",
        "amount": 180.00,
        "type": "expense",
        "category": "Food",
        "paymentMethod": "UPI",
        "timestamp": "2026-11-03T11:00:00.000Z",
        "isDeleted": false
      }
    ]
  }
  ```
- **Response `200 OK`**:
  ```json
  {
    "message": "Sync completed successfully.",
    "syncedAt": "2026-11-03T16:45:00.000Z",
    "appliedClientChangesCount": 1,
    "serverChanges": []
  }
  ```
