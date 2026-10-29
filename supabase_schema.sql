-- ==============================================================================
-- HH TECH HUB ERP - COMPLETE SUPABASE SCHEMA (18 TABLES + SYNC META)
-- Run this script in your Supabase Dashboard: SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Clients
CREATE TABLE IF NOT EXISTS clients (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    "contactPerson" TEXT DEFAULT '',
    email TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    status TEXT DEFAULT 'Active',
    industry TEXT DEFAULT '',
    "totalProjects" INTEGER DEFAULT 0,
    "advancedPayment" DOUBLE PRECISION DEFAULT 0.0,
    "fullPayment" DOUBLE PRECISION DEFAULT 0.0,
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_all_clients" ON clients FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 2. Bank Accounts
CREATE TABLE IF NOT EXISTS bank_accounts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    type TEXT DEFAULT 'Bank',
    "accountNumber" TEXT DEFAULT '',
    "bankName" TEXT DEFAULT '',
    balance DOUBLE PRECISION DEFAULT 0.0,
    status TEXT DEFAULT 'Active',
    "accountScope" TEXT DEFAULT 'Company',
    "openingBalance" DOUBLE PRECISION DEFAULT 0.0,
    "openingBalanceDate" TEXT DEFAULT '',
    "ownerName" TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_bank_accounts" ON bank_accounts;
CREATE POLICY "public_all_bank_accounts" ON bank_accounts FOR ALL USING (true) WITH CHECK (true);

-- Ensure existing bank_accounts table has metadata columns
ALTER TABLE bank_accounts ADD COLUMN IF NOT EXISTS "accountScope" TEXT DEFAULT 'Company';
ALTER TABLE bank_accounts ADD COLUMN IF NOT EXISTS "openingBalance" DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE bank_accounts ADD COLUMN IF NOT EXISTS "openingBalanceDate" TEXT DEFAULT '';
ALTER TABLE bank_accounts ADD COLUMN IF NOT EXISTS "ownerName" TEXT DEFAULT '';

-- 3. Expense Records
CREATE TABLE IF NOT EXISTS expense_records (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL DEFAULT '',
    amount DOUBLE PRECISION DEFAULT 0.0,
    "accountId" TEXT DEFAULT '',
    category TEXT DEFAULT '',
    "vendorName" TEXT DEFAULT '',
    description TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE expense_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_expense_records" ON expense_records;
CREATE POLICY "public_all_expense_records" ON expense_records FOR ALL USING (true) WITH CHECK (true);

-- 4. Income Records
CREATE TABLE IF NOT EXISTS income_records (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL DEFAULT '',
    "clientId" TEXT DEFAULT '',
    "clientName" TEXT DEFAULT '',
    amount DOUBLE PRECISION DEFAULT 0.0,
    "accountId" TEXT DEFAULT '',
    "invoiceNumber" TEXT DEFAULT '',
    description TEXT DEFAULT '',
    status TEXT DEFAULT 'Received',
    "projectId" TEXT,
    "projectName" TEXT,
    "projectPaymentType" TEXT,
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE income_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_income_records" ON income_records;
CREATE POLICY "public_all_income_records" ON income_records FOR ALL USING (true) WITH CHECK (true);

-- 5. Ledger Entries
CREATE TABLE IF NOT EXISTS ledger_entries (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL DEFAULT '',
    "accountId" TEXT DEFAULT '',
    "accountName" TEXT DEFAULT '',
    type TEXT DEFAULT '',
    category TEXT DEFAULT '',
    amount DOUBLE PRECISION DEFAULT 0.0,
    reference TEXT DEFAULT '',
    description TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_ledger_entries" ON ledger_entries;
CREATE POLICY "public_all_ledger_entries" ON ledger_entries FOR ALL USING (true) WITH CHECK (true);

-- 6. Loan Records
CREATE TABLE IF NOT EXISTS loan_records (
    id TEXT PRIMARY KEY,
    "borrowerName" TEXT NOT NULL DEFAULT '',
    type TEXT DEFAULT '',
    amount DOUBLE PRECISION DEFAULT 0.0,
    "remainingBalance" DOUBLE PRECISION DEFAULT 0.0,
    "startDate" TEXT DEFAULT '',
    "endDate" TEXT DEFAULT '',
    status TEXT DEFAULT 'Active',
    description TEXT DEFAULT '',
    repayments JSONB DEFAULT '[]'::jsonb,
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE loan_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_loan_records" ON loan_records;
CREATE POLICY "public_all_loan_records" ON loan_records FOR ALL USING (true) WITH CHECK (true);

-- 7. Advance Records
CREATE TABLE IF NOT EXISTS advance_records (
    id TEXT PRIMARY KEY,
    "employeeId" TEXT DEFAULT '',
    "employeeName" TEXT DEFAULT '',
    amount DOUBLE PRECISION DEFAULT 0.0,
    "requestDate" TEXT DEFAULT '',
    reason TEXT DEFAULT '',
    "repaymentMonths" INTEGER DEFAULT 1,
    "amountRepaid" DOUBLE PRECISION DEFAULT 0.0,
    status TEXT DEFAULT 'Pending',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE advance_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_advance_records" ON advance_records;
CREATE POLICY "public_all_advance_records" ON advance_records FOR ALL USING (true) WITH CHECK (true);

-- 8. Attendance Records
CREATE TABLE IF NOT EXISTS attendance_records (
    id TEXT PRIMARY KEY,
    "employeeId" TEXT DEFAULT '',
    "employeeName" TEXT DEFAULT '',
    date TEXT NOT NULL DEFAULT '',
    status TEXT DEFAULT 'Present',
    "checkIn" TEXT,
    "checkOut" TEXT,
    notes TEXT,
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_attendance_records" ON attendance_records;
CREATE POLICY "public_all_attendance_records" ON attendance_records FOR ALL USING (true) WITH CHECK (true);

-- 9. Employees
CREATE TABLE IF NOT EXISTS employees (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    email TEXT DEFAULT '',
    phones JSONB DEFAULT '[]'::jsonb,
    cnic TEXT DEFAULT '',
    designation TEXT DEFAULT '',
    department TEXT DEFAULT '',
    "joiningDate" TEXT DEFAULT '',
    "leavingDate" TEXT,
    status TEXT DEFAULT 'Active',
    "salaryType" TEXT DEFAULT 'Monthly',
    "baseSalary" DOUBLE PRECISION DEFAULT 0.0,
    "paymentMethod" TEXT DEFAULT 'Bank',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_employees" ON employees;
CREATE POLICY "public_all_employees" ON employees FOR ALL USING (true) WITH CHECK (true);

-- 10. Salary Records
CREATE TABLE IF NOT EXISTS salary_records (
    id TEXT PRIMARY KEY,
    "employeeId" TEXT DEFAULT '',
    "employeeName" TEXT DEFAULT '',
    "payPeriod" TEXT DEFAULT '',
    "baseSalary" DOUBLE PRECISION DEFAULT 0.0,
    allowances DOUBLE PRECISION DEFAULT 0.0,
    deductions DOUBLE PRECISION DEFAULT 0.0,
    "netPaid" DOUBLE PRECISION DEFAULT 0.0,
    "paymentDate" TEXT DEFAULT '',
    status TEXT DEFAULT 'Paid',
    "paymentMethod" TEXT DEFAULT 'Bank',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE salary_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_salary_records" ON salary_records;
CREATE POLICY "public_all_salary_records" ON salary_records FOR ALL USING (true) WITH CHECK (true);

-- 11. Assets
CREATE TABLE IF NOT EXISTS assets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    type TEXT DEFAULT '',
    "serialNumber" TEXT DEFAULT '',
    "purchaseDate" TEXT DEFAULT '',
    cost DOUBLE PRECISION DEFAULT 0.0,
    status TEXT DEFAULT 'Active',
    condition TEXT DEFAULT 'Good',
    "assignedToId" TEXT,
    "assignedToName" TEXT,
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_assets" ON assets;
CREATE POLICY "public_all_assets" ON assets FOR ALL USING (true) WITH CHECK (true);

-- 12. Inventory Items
CREATE TABLE IF NOT EXISTS inventory_items (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    category TEXT DEFAULT '',
    quantity INTEGER DEFAULT 0,
    "minQuantity" INTEGER DEFAULT 0,
    unit TEXT DEFAULT '',
    "pricePerUnit" DOUBLE PRECISION DEFAULT 0.0,
    "lastRestockedDate" TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_inventory_items" ON inventory_items;
CREATE POLICY "public_all_inventory_items" ON inventory_items FOR ALL USING (true) WITH CHECK (true);

-- 13. Projects
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    description TEXT DEFAULT '',
    "clientId" TEXT DEFAULT '',
    "clientName" TEXT DEFAULT '',
    "startDate" TEXT DEFAULT '',
    "endDate" TEXT DEFAULT '',
    status TEXT DEFAULT 'In Progress',
    budget DOUBLE PRECISION DEFAULT 0.0,
    "advancedPayment" DOUBLE PRECISION DEFAULT 0.0,
    "partialPayments" DOUBLE PRECISION DEFAULT 0.0,
    "finalPayment" DOUBLE PRECISION DEFAULT 0.0,
    "paymentStatus" TEXT DEFAULT 'Pending',
    "bankAccountId" TEXT DEFAULT '',
    "bankAccountName" TEXT DEFAULT '',
    "accountHolder" TEXT DEFAULT '',
    "teamMembers" JSONB DEFAULT '[]'::jsonb,
    "clientPaymentSource" TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_projects" ON projects;
CREATE POLICY "public_all_projects" ON projects FOR ALL USING (true) WITH CHECK (true);

-- 14. Project Tasks
CREATE TABLE IF NOT EXISTS project_tasks (
    id TEXT PRIMARY KEY,
    "projectId" TEXT DEFAULT '',
    "projectName" TEXT DEFAULT '',
    title TEXT NOT NULL DEFAULT '',
    description TEXT DEFAULT '',
    "assigneeId" TEXT DEFAULT '',
    "assigneeName" TEXT DEFAULT '',
    "dueDate" TEXT DEFAULT '',
    priority TEXT DEFAULT 'Medium',
    status TEXT DEFAULT 'To Do',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE project_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_project_tasks" ON project_tasks;
CREATE POLICY "public_all_project_tasks" ON project_tasks FOR ALL USING (true) WITH CHECK (true);

-- 15. Timesheet Entries
CREATE TABLE IF NOT EXISTS timesheet_entries (
    id TEXT PRIMARY KEY,
    "employeeId" TEXT DEFAULT '',
    "employeeName" TEXT DEFAULT '',
    "projectId" TEXT DEFAULT '',
    "projectName" TEXT DEFAULT '',
    "taskTitle" TEXT DEFAULT '',
    date TEXT NOT NULL DEFAULT '',
    hours DOUBLE PRECISION DEFAULT 0.0,
    description TEXT DEFAULT '',
    status TEXT DEFAULT 'Submitted',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE timesheet_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_timesheet_entries" ON timesheet_entries;
CREATE POLICY "public_all_timesheet_entries" ON timesheet_entries FOR ALL USING (true) WITH CHECK (true);

-- 16. Purchase Orders
CREATE TABLE IF NOT EXISTS purchase_orders (
    id TEXT PRIMARY KEY,
    "vendorId" TEXT DEFAULT '',
    "vendorName" TEXT DEFAULT '',
    date TEXT NOT NULL DEFAULT '',
    "deliveryDate" TEXT DEFAULT '',
    items JSONB DEFAULT '[]'::jsonb,
    subtotal DOUBLE PRECISION DEFAULT 0.0,
    tax DOUBLE PRECISION DEFAULT 0.0,
    total DOUBLE PRECISION DEFAULT 0.0,
    status TEXT DEFAULT 'Pending',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_purchase_orders" ON purchase_orders;
CREATE POLICY "public_all_purchase_orders" ON purchase_orders FOR ALL USING (true) WITH CHECK (true);

-- 17. Products
CREATE TABLE IF NOT EXISTS products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    description TEXT DEFAULT '',
    category TEXT DEFAULT '',
    price DOUBLE PRECISION DEFAULT 0.0,
    status TEXT DEFAULT 'Active',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_products" ON products;
CREATE POLICY "public_all_products" ON products FOR ALL USING (true) WITH CHECK (true);

-- 18. Sales Invoices
CREATE TABLE IF NOT EXISTS sales_invoices (
    id TEXT PRIMARY KEY,
    "clientId" TEXT DEFAULT '',
    "clientName" TEXT DEFAULT '',
    date TEXT NOT NULL DEFAULT '',
    "dueDate" TEXT DEFAULT '',
    items JSONB DEFAULT '[]'::jsonb,
    subtotal DOUBLE PRECISION DEFAULT 0.0,
    tax DOUBLE PRECISION DEFAULT 0.0,
    total DOUBLE PRECISION DEFAULT 0.0,
    status TEXT DEFAULT 'Unpaid',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE sales_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_sales_invoices" ON sales_invoices;
CREATE POLICY "public_all_sales_invoices" ON sales_invoices FOR ALL USING (true) WITH CHECK (true);

-- 19. Sync Meta (Heartbeat & sync status)
CREATE TABLE IF NOT EXISTS sync_meta (
    id TEXT PRIMARY KEY,
    "updatedAt" TEXT NOT NULL DEFAULT ''
);
ALTER TABLE sync_meta ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_sync_meta" ON sync_meta;
CREATE POLICY "public_all_sync_meta" ON sync_meta FOR ALL USING (true) WITH CHECK (true);

-- 20. Ledger Entries
CREATE TABLE IF NOT EXISTS ledger_entries (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL DEFAULT '',
    "accountId" TEXT DEFAULT '',
    "accountName" TEXT DEFAULT '',
    type TEXT DEFAULT 'Debit',
    category TEXT DEFAULT '',
    amount DOUBLE PRECISION DEFAULT 0.0,
    reference TEXT DEFAULT '',
    description TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_ledger_entries" ON ledger_entries;
CREATE POLICY "public_all_ledger_entries" ON ledger_entries FOR ALL USING (true) WITH CHECK (true);

-- 21. App Users (Authentication & RBAC Users)
CREATE TABLE IF NOT EXISTS app_users (
    id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL DEFAULT '',
    username TEXT UNIQUE NOT NULL DEFAULT '',
    email TEXT DEFAULT '',
    password_hash TEXT NOT NULL DEFAULT '',
    salt TEXT NOT NULL DEFAULT '',
    role TEXT NOT NULL DEFAULT 'Super Admin',
    is_active BOOLEAN DEFAULT true,
    is_super_admin BOOLEAN DEFAULT false,
    last_active TEXT DEFAULT '',
    created_at TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_app_users" ON app_users;
DROP POLICY IF EXISTS "authenticated_all_app_users" ON app_users;
CREATE POLICY "authenticated_all_app_users" ON app_users FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 22. App Roles (Roles & Granular Permission Matrix)
CREATE TABLE IF NOT EXISTS app_roles (
    id TEXT PRIMARY KEY,
    role_name TEXT UNIQUE NOT NULL DEFAULT '',
    description TEXT DEFAULT '',
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    can_change_username BOOLEAN DEFAULT true,
    can_change_password BOOLEAN DEFAULT true,
    permissions JSONB DEFAULT '{}'::jsonb,
    created_at TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE app_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_app_roles" ON app_roles;
DROP POLICY IF EXISTS "authenticated_all_app_roles" ON app_roles;
CREATE POLICY "authenticated_all_app_roles" ON app_roles FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 23. Audit Logs (System Activity & Tracking for Super Admin)
CREATE TABLE IF NOT EXISTS audit_logs (
    id TEXT PRIMARY KEY,
    timestamp TEXT NOT NULL DEFAULT '',
    "user" TEXT NOT NULL DEFAULT '',
    action TEXT NOT NULL DEFAULT '',
    module TEXT NOT NULL DEFAULT '',
    ip_address TEXT DEFAULT '192.168.1.1',
    created_at TEXT DEFAULT '',
    "updatedAt" TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_all_audit_logs" ON audit_logs;
DROP POLICY IF EXISTS "authenticated_all_audit_logs" ON audit_logs;
CREATE POLICY "authenticated_all_audit_logs" ON audit_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);



