# OneSpend by AR1 — Modern Offline Expense Tracker

Crafted by **AR1studios** (`v1.0.0`)
A modern, production-grade, 100% offline and private cross-platform financial tracking app built with **Flutter**, **Riverpod**, and **SQLite**.

---

## 🌟 Key Features

- **Brand & Identity**:
  - Desktop Monogram: `[ 1S ]` with emerald green highlight (`#10B981`).
  - Mobile Brand Tag: `OneSpend by AR1`.
  - Vault Storage: Encapsulated in `onespend_vault.db`.
  - Export: Standardized pattern `onespend_export_YYYY_MM.csv`.
- **Platform Implementations**:
  - **Windows Desktop (`AeroSpend` View)**:
    - Fixed 250px dark charcoal sidebar (`#161920`).
    - Top Action Bar with `Ctrl + K` search, month/year selector, and `+ Add Transaction` (`Ctrl + N`).
    - Minimum window size enforced at 1024 x 720.
    - 2-Column dashboard layout with 3 metric cards, bezier curved analytics area chart, 5-category donut chart, and interactive data table with row hover actions.
  - **Android Mobile (`MobileDashboard`)**:
    - `#0F1115` OLED dark canvas.
    - Hero balance card with Inflow/Outflow split.
    - Quick action buttons: `[Scan]`, `[Add]`, `[Transfer]`, `[Insights]`.
    - Centered spending breakdown donut chart.
    - Recent transactions with category squircle badges and swipe-to-delete.
    - Curved bottom navigation bar with a center-docked emerald/coral gradient FAB.

---

## 📂 Configuration Details

| Platform | Identifier / Window Title |
| :--- | :--- |
| **Android Application ID** | `com.ar1studios.onespend` |
| **Android Label** | `OneSpend` |
| **Windows Executable Title** | `OneSpend by AR1 — AR1studios` |
| **Minimum Window Resolution** | `1024 x 720` |
| **Local Database Vault** | `onespend_vault.db` |
| **Default Export File** | `onespend_export_YYYY_MM.csv` |

---

## ⌨️ Desktop Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Ctrl + N` | Open the "Add Transaction" dialog from anywhere |
| `Ctrl + K` | Focus top search field |
| `Esc` | Dismiss / Close open modal dialog |
