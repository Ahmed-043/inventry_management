# Inventory Management System

A robust, feature-rich Flutter application designed for businesses to manage their stock, sales, purchases, and customer/supplier relationships efficiently. This application is optimized for desktop and provides a comprehensive suite of tools for inventory tracking and financial reporting.



<div align="center">

## [Download for Windows](https://github.com/Ahmed-043/inventry_management/releases/tag/windows)

</div>

## 🚀 Features

### 📦 Product Management
- **Detailed Inventory:** Track products with SKU, base price, weight, and stock levels.
- **Low Stock Alerts:** Automated notifications when stock falls below a defined threshold.
- **Categorization:** Organize products into custom categories for easier navigation.
- **Dynamic Pricing:** Manage base prices and track stock movements.

### 🧾 Order & Transaction Tracking
- **Sales & Purchases:** Create and manage both "Buy" (Purchase) and "Sell" (Sales) orders.
- **Order Status:** Track orders through states: Pending, Completed, or Canceled.
- **Financial Status:** Monitor Payment Status (Pending, Paid, Overdue) and Due Dates.
- **Itemized Billing:** Support for tax, discounts, and detailed weight-based pricing.

### 👥 Stakeholder Management
- **Customers & Suppliers:** Maintain a directory of persons categorized as 'customer' or 'supplier'.
- **Account Ledger:** Track total payments, addresses, and contact information for each entity.

### 💳 Payment & Ledger
- **Multiple Payment Methods:** Support for Cash, Bank, Digital, and other payment modes.
- **Transaction History:** Detailed logs of all financial transactions tied to orders and persons.
- **Debt Tracking:** Easily identify overdue payments and pending balances.

### 📊 Reports & Analytics
- **Dashboard:** At-a-glance view of business health, stock alerts, and recent activities.
- **Inventory Movements:** Full audit trail for every stock change (Sales, Purchases, Returns, Adjustments).
- **Exporting:** Generate reports in PDF and Excel formats for external auditing.

### 🛡️ Security & Reliability
- **Local Authentication:** Biometric/local security integration for sensitive data.
- **Data Backup:** Automated backup system (Daily/Weekly/Monthly) to a local directory.
- **Offline First:** Powered by a robust SQLite database for reliable performance without constant internet.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **State Management:** [Riverpod](https://riverpod.dev)
- **Database:** [SQLite (sqflite)](https://pub.dev/packages/sqflite)
- **Charts:** [fl_chart](https://pub.dev/packages/fl_chart)
- **Reporting:** [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing), [syncfusion_flutter_xlsio](https://pub.dev/packages/syncfusion_flutter_xlsio)
- **Desktop Integration:** [window_manager](https://pub.dev/packages/window_manager), [desktop_drop](https://pub.dev/packages/desktop_drop)

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK (^3.10.0)
- Dart SDK

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ahmed-043/inventry_management.git
   cd inventry_management
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run -d windows # For Windows Desktop
   # OR
   flutter run -d linux   # For Linux
   # OR
   flutter run -d macos   # For macOS
   ```

## 📁 Project Structure

```text
lib/
├── Database/          # SQLite schema and database helper logic
├── Home_Page/         # Main dashboard and feature panels
│   ├── Dashboard_Panel/
│   ├── Products_Panel/
│   └── ...
├── Shared_Widgets/    # Reusable UI components (upload boxes, custom scrolls)
├── Signin/            # Authentication and onboarding screens
└── main.dart          # Application entry point
```

## 📝 License

This project is for private use as per the `publish_to: 'none'` setting in `pubspec.yaml`. Contact the author for licensing inquiries.
