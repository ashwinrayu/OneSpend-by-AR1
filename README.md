# OneSpend by AR1 — Modern Offline-First Expense Tracker

Crafted by **AR1studios** (`v1.0.0`)  
A modern, production-grade, offline-first cross-platform financial tracking system built with **Flutter**, **Riverpod**, **SQLite**, and backed by a live **Node.js Express REST API** connecting to **PostgreSQL on Supabase**.

---

## 🌟 Key Features

- **Brand & Identity**:
  - Desktop Monogram: `[ 1S ]` with emerald green highlight (`#10B981`).
  - Mobile Brand Tag: `OneSpend by AR1`.
  - Vault Storage: Encapsulated in `onespend_vault.db`.
  - Export: Standardized pattern `onespend_export_YYYY_MM.csv`.
- **Offline-First Delta-Sync Engine**:
  - Zero-latency local reads/writes hitting SQLite instantly.
  - Background delta-sync with live Render API (`https://onespend-by-ar1.onrender.com`).
  - Animated cloud status badge in top navigation (Synced, Syncing, Offline/Guest, Error retry).
- **Authentication & Guest Mode**:
  - JWT-secured authentication with bcrypt password hashing.
  - Secure token storage via `flutter_secure_storage` (Credential Manager on Windows, EncryptedSharedPreferences on Android).
  - Prominent **"Continue Offline (Guest)"** mode allowing 100% private local usage without creating an account.
- **Platform Implementations**:
  - **Windows Desktop View**:
    - Fixed 250px dark charcoal sidebar (`#161920`).
    - Top Action Bar with `Ctrl + K` search, month/year selector, Cloud Sync badge, and `+ Add Transaction` (`Ctrl + N`).
    - Minimum window size enforced at $1024 \times 720$.
    - 2-Column dashboard layout with 3 metric cards, bezier curved analytics area chart (`fl_chart`), 5-category donut chart, and interactive data table with row hover actions.
  - **Android Mobile (`MobileDashboard`)**:
    - `#0F1115` OLED dark canvas.
    - Hero balance card with Inflow/Outflow split.
    - Quick action buttons: `[Scan]`, `[Add]`, `[Transfer]`, `[Insights]`.
    - Centered spending breakdown donut chart.
    - Recent transactions with category squircle badges and swipe-to-delete.
    - Curved bottom navigation bar with a center-docked emerald/coral gradient FAB.

---

## 📂 Configuration Details

| Platform / Component | Identifier / Detail |
| :--- | :--- |
| **Android Application ID** | `com.ar1studios.onespend` |
| **Android Label** | `OneSpend` |
| **Windows Executable Title** | `OneSpend by AR1 — AR1studios` |
| **Minimum Window Resolution** | `1024 x 720` |
| **Local Database Vault** | `onespend_vault.db` |
| **Default Export File** | `onespend_export_YYYY_MM.csv` |
| **Cloud Backend Base URL** | `https://onespend-by-ar1.onrender.com` |
| **Cloud Database** | PostgreSQL on Supabase via `DATABASE_URL` |

---

## ⌨️ Desktop Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Ctrl + N` | Open the "Add Transaction" dialog from anywhere |
| `Ctrl + K` | Focus top search field |
| `Esc` | Dismiss / Close open modal dialog |

---

## 🛠️ Build & Release Automation

### Automated One-Click Script
To build the Windows executable and Android release APK:
```cmd
build_release.bat
```

Generated artifact outputs:
- **Windows Desktop Executable**: `build\windows\x64\runner\Release\onespend.exe`
- **Android Release APK**: `build\app\outputs\flutter-apk\app-release.apk`

---

## 🚀 Running the Project

### 1. Flutter Client
```bash
# Windows Desktop
flutter run -d windows

# Android Device / Emulator
flutter run -d android

# Chrome / Web Preview
flutter run -d chrome
```

### 2. Node.js Backend API (Optional Local Dev)
```bash
cd backend
npm install
npm run dev # Starts on http://localhost:5000
```
