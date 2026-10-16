# 🏢 HH Tech Hub - Software House ERP System

A complete, modern, and easy-to-use **Enterprise Resource Planning (ERP)** software built with **Flutter** specifically tailored for software houses, IT agencies, and tech businesses.

---

## 🚀 Key Highlights
- **Multi-Platform:** Runs smoothly on **Windows Desktop** and **Web Browser**.
- **Offline First:** Fast and secure local database (SQLite) with zero lag.
- **Clean UI:** Intuitive modern dashboard with light and dark theme support.
- **One-Click Backup:** Export, import, backup, and restore your full business data anytime.

---

## 📌 Main Modules & Features

### 1. 📊 Executive Dashboard
- High-level business overview at a glance.
- Real-time income vs. expense statistics.
- Active projects and employee count summaries.

### 2. 👥 Human Resources (HR)
- **Employees Management:** Add, edit, and view complete employee profiles and job details.
- **Departments:** Organize staff by technical and operational departments.
- **Attendance Tracking:** Daily attendance recording, present/absent logs.
- **Payroll & Salaries:** Calculate monthly salaries, bonuses, and deductions with ease.
- **Staff Advances:** Record and manage employee advance payments.

### 3. 💰 Finance & Accounts
- **Accounts & Wallets:** Manage multiple company bank accounts and cash wallets.
- **Income Tracker:** Record client payments, project revenue, and other earnings.
- **Expense Tracker:** Log daily office expenses, server costs, utilities, and vendor payouts.
- **General Ledger:** Complete double-entry debit/credit ledger for full financial clarity.
- **Loans:** Track company loans, liabilities, and repayment schedules.
- **Financial Reports:** Instant Profit & Loss reports, Balance Sheets, and monthly summaries.

### 4. 💻 Projects & Tasks
- Track all client projects from kickoff to completion.
- Set milestones, deadlines, and delivery statuses.
- Assign tasks to team members and monitor progress.

### 5. 🤝 Clients Management
- Store client contact details, company profiles, and requirements.
- View project history and billing records per client.

### 6. 📦 Inventory & Company Assets
- Maintain records of office assets (laptops, monitors, furniture, servers).
- Track asset conditions, values, and assignees.

### 7. 📈 Reports & Analytics
- Comprehensive operational and financial reports.
- Export transaction ledgers and reports to PDF and Excel.

### 8. ⚙️ Administration & Settings
- Company profile customization.
- System data backup, JSON export, and restore functionality.
- UI theme settings.

---

## 🛠️ Tech Stack
- **Framework:** Flutter (Dart)
- **Database:** SQLite / Drift (Native & Web WASM support)
- **State Management:** Riverpod
- **Supported Targets:** Windows Desktop, Web

---

## 💻 How to Run the Project

### Prerequisites
- [Flutter SDK](https://flutter.dev/) installed on your computer.

### Step 1: Clone or Open the Repository
```bash
git clone https://github.com/Haseeb-ML/HH-Tech-Hub.git
cd HH-Tech-Hub
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Run the Application
- **For Windows Desktop:**
  ```bash
  flutter run -d windows
  ```
- **For Web Browser:**
  ```bash
  flutter run -d chrome
  ```

---

## 📦 How to Build for Production

- **Build Windows Executable (.exe):**
  ```bash
  flutter build windows
  ```
- **Build Web Version:**
  ```bash
  flutter build web --release
  ```

---

## 📄 License
Developed for **Haseeb-ML**. All rights reserved.
