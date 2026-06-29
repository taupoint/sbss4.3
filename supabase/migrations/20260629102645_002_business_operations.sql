/*
# SI Building Solutions ERP — Business Operations Schema (Migration 002)

## Overview
Creates tables for core business operations:
- Quotations and their line items
- Purchase orders, GRN, purchase payments
- Sales orders, invoices, payments
- Projects and tasks
- Delivery management
- Accounting (chart of accounts, journal entries)
- Employees and attendance
- Online store orders
- Activity log

## New Tables
- `quotations` / `quotation_items`
- `purchase_orders` / `purchase_order_items` / `goods_receipt_notes`
- `invoices` / `invoice_items`
- `payments`
- `projects` / `project_tasks`
- `deliveries` / `delivery_items`
- `accounts` (chart of accounts)
- `journal_entries` / `journal_lines`
- `employees` / `attendance`
- `online_orders` / `online_order_items`
- `activity_logs`
- `warranty_records`

## Security
- RLS enabled, authenticated users have full access (internal ERP)
*/

-- ============================================================
-- QUOTATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS quotations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  quote_number text NOT NULL,
  customer_id uuid NOT NULL REFERENCES customers(id),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft','sent','viewed','accepted','rejected','expired','converted')),
  issue_date date NOT NULL DEFAULT CURRENT_DATE,
  expiry_date date,
  subtotal decimal(15,2) NOT NULL DEFAULT 0,
  discount_amount decimal(15,2) NOT NULL DEFAULT 0,
  tax_amount decimal(15,2) NOT NULL DEFAULT 0,
  total_amount decimal(15,2) NOT NULL DEFAULT 0,
  notes text,
  terms_conditions text,
  created_by uuid REFERENCES profiles(id),
  converted_to uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS quotes_tenant_num ON quotations(tenant_id, quote_number);
CREATE INDEX IF NOT EXISTS quotes_customer ON quotations(customer_id);
CREATE INDEX IF NOT EXISTS quotes_status ON quotations(status);

ALTER TABLE quotations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "q_select" ON quotations; CREATE POLICY "q_select" ON quotations FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "q_insert" ON quotations; CREATE POLICY "q_insert" ON quotations FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "q_update" ON quotations; CREATE POLICY "q_update" ON quotations FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "q_delete" ON quotations; CREATE POLICY "q_delete" ON quotations FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS quotation_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id uuid NOT NULL REFERENCES quotations(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id),
  variant_id uuid REFERENCES product_variants(id),
  description text,
  quantity decimal(15,3) NOT NULL DEFAULT 1,
  unit_price decimal(15,2) NOT NULL DEFAULT 0,
  discount_percent decimal(5,2) NOT NULL DEFAULT 0,
  tax_rate decimal(5,2) NOT NULL DEFAULT 0,
  subtotal decimal(15,2) NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0
);

ALTER TABLE quotation_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "qi_select" ON quotation_items; CREATE POLICY "qi_select" ON quotation_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "qi_insert" ON quotation_items; CREATE POLICY "qi_insert" ON quotation_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "qi_update" ON quotation_items; CREATE POLICY "qi_update" ON quotation_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "qi_delete" ON quotation_items; CREATE POLICY "qi_delete" ON quotation_items FOR DELETE TO authenticated USING (true);

-- ============================================================
-- PURCHASE ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS purchase_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  po_number text NOT NULL,
  supplier_id uuid NOT NULL REFERENCES suppliers(id),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft','pending_approval','approved','partially_received','received','cancelled')),
  order_date date NOT NULL DEFAULT CURRENT_DATE,
  expected_date date,
  subtotal decimal(15,2) NOT NULL DEFAULT 0,
  discount_amount decimal(15,2) NOT NULL DEFAULT 0,
  tax_amount decimal(15,2) NOT NULL DEFAULT 0,
  shipping_cost decimal(15,2) NOT NULL DEFAULT 0,
  total_amount decimal(15,2) NOT NULL DEFAULT 0,
  amount_paid decimal(15,2) NOT NULL DEFAULT 0,
  warehouse_id uuid REFERENCES warehouses(id),
  notes text,
  terms text,
  approved_by uuid REFERENCES profiles(id),
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS po_tenant_num ON purchase_orders(tenant_id, po_number);
CREATE INDEX IF NOT EXISTS po_supplier ON purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS po_status ON purchase_orders(status);

ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "po_select" ON purchase_orders; CREATE POLICY "po_select" ON purchase_orders FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "po_insert" ON purchase_orders; CREATE POLICY "po_insert" ON purchase_orders FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "po_update" ON purchase_orders; CREATE POLICY "po_update" ON purchase_orders FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "po_delete" ON purchase_orders; CREATE POLICY "po_delete" ON purchase_orders FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS purchase_order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id uuid NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id),
  variant_id uuid REFERENCES product_variants(id),
  quantity decimal(15,3) NOT NULL DEFAULT 1,
  received_quantity decimal(15,3) NOT NULL DEFAULT 0,
  unit_cost decimal(15,2) NOT NULL DEFAULT 0,
  tax_rate decimal(5,2) NOT NULL DEFAULT 0,
  subtotal decimal(15,2) NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0
);

ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "poi_select" ON purchase_order_items; CREATE POLICY "poi_select" ON purchase_order_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "poi_insert" ON purchase_order_items; CREATE POLICY "poi_insert" ON purchase_order_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "poi_update" ON purchase_order_items; CREATE POLICY "poi_update" ON purchase_order_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "poi_delete" ON purchase_order_items; CREATE POLICY "poi_delete" ON purchase_order_items FOR DELETE TO authenticated USING (true);

-- GRN (Goods Receipt Note)
CREATE TABLE IF NOT EXISTS goods_receipt_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  grn_number text NOT NULL,
  purchase_order_id uuid REFERENCES purchase_orders(id),
  supplier_id uuid NOT NULL REFERENCES suppliers(id),
  warehouse_id uuid NOT NULL REFERENCES warehouses(id),
  received_date date NOT NULL DEFAULT CURRENT_DATE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','verified','posted')),
  notes text,
  received_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE goods_receipt_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "grn_select" ON goods_receipt_notes; CREATE POLICY "grn_select" ON goods_receipt_notes FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "grn_insert" ON goods_receipt_notes; CREATE POLICY "grn_insert" ON goods_receipt_notes FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "grn_update" ON goods_receipt_notes; CREATE POLICY "grn_update" ON goods_receipt_notes FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "grn_delete" ON goods_receipt_notes; CREATE POLICY "grn_delete" ON goods_receipt_notes FOR DELETE TO authenticated USING (true);

-- ============================================================
-- INVOICES (Sales)
-- ============================================================
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  invoice_number text NOT NULL,
  customer_id uuid NOT NULL REFERENCES customers(id),
  quotation_id uuid REFERENCES quotations(id),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft','sent','partially_paid','paid','overdue','cancelled','refunded')),
  invoice_date date NOT NULL DEFAULT CURRENT_DATE,
  due_date date,
  subtotal decimal(15,2) NOT NULL DEFAULT 0,
  discount_amount decimal(15,2) NOT NULL DEFAULT 0,
  tax_amount decimal(15,2) NOT NULL DEFAULT 0,
  total_amount decimal(15,2) NOT NULL DEFAULT 0,
  amount_paid decimal(15,2) NOT NULL DEFAULT 0,
  payment_terms text,
  notes text,
  is_pos boolean NOT NULL DEFAULT false,
  warehouse_id uuid REFERENCES warehouses(id),
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Add balance_due as computed column
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS balance_due decimal(15,2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED;

CREATE UNIQUE INDEX IF NOT EXISTS inv_tenant_num ON invoices(tenant_id, invoice_number);
CREATE INDEX IF NOT EXISTS inv_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS inv_status ON invoices(status);
CREATE INDEX IF NOT EXISTS inv_date ON invoices(invoice_date DESC);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "inv_select" ON invoices; CREATE POLICY "inv_select" ON invoices FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "inv_insert" ON invoices; CREATE POLICY "inv_insert" ON invoices FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "inv_update" ON invoices; CREATE POLICY "inv_update" ON invoices FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "inv_delete" ON invoices; CREATE POLICY "inv_delete" ON invoices FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS invoice_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id),
  variant_id uuid REFERENCES product_variants(id),
  description text,
  quantity decimal(15,3) NOT NULL DEFAULT 1,
  unit_price decimal(15,2) NOT NULL DEFAULT 0,
  discount_percent decimal(5,2) NOT NULL DEFAULT 0,
  tax_rate decimal(5,2) NOT NULL DEFAULT 0,
  subtotal decimal(15,2) NOT NULL DEFAULT 0,
  cost_price decimal(15,2) NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0
);

ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ii_select" ON invoice_items; CREATE POLICY "ii_select" ON invoice_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "ii_insert" ON invoice_items; CREATE POLICY "ii_insert" ON invoice_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "ii_update" ON invoice_items; CREATE POLICY "ii_update" ON invoice_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "ii_delete" ON invoice_items; CREATE POLICY "ii_delete" ON invoice_items FOR DELETE TO authenticated USING (true);

-- ============================================================
-- PAYMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  payment_number text NOT NULL,
  payment_type text NOT NULL CHECK (payment_type IN ('received','made')),
  reference_type text NOT NULL CHECK (reference_type IN ('invoice','purchase_order','advance','refund')),
  reference_id uuid NOT NULL,
  customer_id uuid REFERENCES customers(id),
  supplier_id uuid REFERENCES suppliers(id),
  amount decimal(15,2) NOT NULL,
  payment_method text NOT NULL DEFAULT 'cash'
    CHECK (payment_method IN ('cash','bank_transfer','bkash','nagad','rocket','sslcommerz','cheque','card')),
  payment_date date NOT NULL DEFAULT CURRENT_DATE,
  reference_number text,
  bank_account text,
  notes text,
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS pay_reference ON payments(reference_id);
CREATE INDEX IF NOT EXISTS pay_date ON payments(payment_date DESC);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pay_select" ON payments; CREATE POLICY "pay_select" ON payments FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "pay_insert" ON payments; CREATE POLICY "pay_insert" ON payments FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "pay_update" ON payments; CREATE POLICY "pay_update" ON payments FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "pay_delete" ON payments; CREATE POLICY "pay_delete" ON payments FOR DELETE TO authenticated USING (true);

-- ============================================================
-- PROJECTS
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  project_number text NOT NULL,
  name text NOT NULL,
  customer_id uuid REFERENCES customers(id),
  status text NOT NULL DEFAULT 'planning'
    CHECK (status IN ('planning','active','on_hold','completed','cancelled')),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent')),
  start_date date,
  end_date date,
  estimated_budget decimal(15,2),
  actual_cost decimal(15,2) NOT NULL DEFAULT 0,
  revenue decimal(15,2) NOT NULL DEFAULT 0,
  progress_percent integer NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  description text,
  location text,
  project_manager uuid REFERENCES profiles(id),
  image_url text,
  tags text[],
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS proj_tenant_num ON projects(tenant_id, project_number);
CREATE INDEX IF NOT EXISTS proj_status ON projects(status);
CREATE INDEX IF NOT EXISTS proj_customer ON projects(customer_id);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "proj_select" ON projects; CREATE POLICY "proj_select" ON projects FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "proj_insert" ON projects; CREATE POLICY "proj_insert" ON projects FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "proj_update" ON projects; CREATE POLICY "proj_update" ON projects FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "proj_delete" ON projects; CREATE POLICY "proj_delete" ON projects FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS project_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'todo' CHECK (status IN ('todo','in_progress','review','done')),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent')),
  assigned_to uuid REFERENCES profiles(id),
  due_date date,
  completed_at timestamptz,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE project_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pt_select" ON project_tasks; CREATE POLICY "pt_select" ON project_tasks FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "pt_insert" ON project_tasks; CREATE POLICY "pt_insert" ON project_tasks FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "pt_update" ON project_tasks; CREATE POLICY "pt_update" ON project_tasks FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "pt_delete" ON project_tasks; CREATE POLICY "pt_delete" ON project_tasks FOR DELETE TO authenticated USING (true);

-- ============================================================
-- DELIVERIES
-- ============================================================
CREATE TABLE IF NOT EXISTS deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  delivery_number text NOT NULL,
  invoice_id uuid REFERENCES invoices(id),
  customer_id uuid NOT NULL REFERENCES customers(id),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','assigned','in_transit','delivered','failed','returned')),
  delivery_date date,
  delivered_at timestamptz,
  delivery_address text,
  delivery_city text,
  driver_id uuid REFERENCES profiles(id),
  vehicle_number text,
  notes text,
  proof_of_delivery_url text,
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS dlv_tenant_num ON deliveries(tenant_id, delivery_number);
CREATE INDEX IF NOT EXISTS dlv_status ON deliveries(status);
CREATE INDEX IF NOT EXISTS dlv_customer ON deliveries(customer_id);

ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "dlv_select" ON deliveries; CREATE POLICY "dlv_select" ON deliveries FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "dlv_insert" ON deliveries; CREATE POLICY "dlv_insert" ON deliveries FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "dlv_update" ON deliveries; CREATE POLICY "dlv_update" ON deliveries FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "dlv_delete" ON deliveries; CREATE POLICY "dlv_delete" ON deliveries FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS delivery_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id uuid NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id),
  quantity decimal(15,3) NOT NULL DEFAULT 1,
  delivered_quantity decimal(15,3) NOT NULL DEFAULT 0
);

ALTER TABLE delivery_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "di_select" ON delivery_items; CREATE POLICY "di_select" ON delivery_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "di_insert" ON delivery_items; CREATE POLICY "di_insert" ON delivery_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "di_update" ON delivery_items; CREATE POLICY "di_update" ON delivery_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "di_delete" ON delivery_items; CREATE POLICY "di_delete" ON delivery_items FOR DELETE TO authenticated USING (true);

-- ============================================================
-- ACCOUNTING — Chart of Accounts
-- ============================================================
CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  code text NOT NULL,
  name text NOT NULL,
  account_type text NOT NULL
    CHECK (account_type IN ('asset','liability','equity','revenue','expense')),
  parent_id uuid REFERENCES accounts(id),
  is_cash boolean NOT NULL DEFAULT false,
  is_bank boolean NOT NULL DEFAULT false,
  bank_name text,
  account_number text,
  balance decimal(15,2) NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS acc_tenant_code ON accounts(tenant_id, code);

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "acc_select" ON accounts; CREATE POLICY "acc_select" ON accounts FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "acc_insert" ON accounts; CREATE POLICY "acc_insert" ON accounts FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "acc_update" ON accounts; CREATE POLICY "acc_update" ON accounts FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "acc_delete" ON accounts; CREATE POLICY "acc_delete" ON accounts FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  entry_number text NOT NULL,
  entry_date date NOT NULL DEFAULT CURRENT_DATE,
  description text NOT NULL,
  reference_type text,
  reference_id uuid,
  total_debit decimal(15,2) NOT NULL DEFAULT 0,
  total_credit decimal(15,2) NOT NULL DEFAULT 0,
  is_posted boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "je_select" ON journal_entries; CREATE POLICY "je_select" ON journal_entries FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "je_insert" ON journal_entries; CREATE POLICY "je_insert" ON journal_entries FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "je_update" ON journal_entries; CREATE POLICY "je_update" ON journal_entries FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "je_delete" ON journal_entries; CREATE POLICY "je_delete" ON journal_entries FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS journal_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id uuid NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES accounts(id),
  description text,
  debit decimal(15,2) NOT NULL DEFAULT 0,
  credit decimal(15,2) NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0
);

ALTER TABLE journal_lines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "jl_select" ON journal_lines; CREATE POLICY "jl_select" ON journal_lines FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "jl_insert" ON journal_lines; CREATE POLICY "jl_insert" ON journal_lines FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "jl_update" ON journal_lines; CREATE POLICY "jl_update" ON journal_lines FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "jl_delete" ON journal_lines; CREATE POLICY "jl_delete" ON journal_lines FOR DELETE TO authenticated USING (true);

-- ============================================================
-- EMPLOYEES
-- ============================================================
CREATE TABLE IF NOT EXISTS employees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  employee_id text NOT NULL,
  profile_id uuid REFERENCES profiles(id),
  full_name text NOT NULL,
  email text,
  phone text,
  designation text NOT NULL,
  department text NOT NULL,
  join_date date NOT NULL,
  salary decimal(15,2) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','on_leave','resigned','terminated')),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "emp_select" ON employees; CREATE POLICY "emp_select" ON employees FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "emp_insert" ON employees; CREATE POLICY "emp_insert" ON employees FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "emp_update" ON employees; CREATE POLICY "emp_update" ON employees FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "emp_delete" ON employees; CREATE POLICY "emp_delete" ON employees FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  date date NOT NULL,
  check_in timestamptz,
  check_out timestamptz,
  status text NOT NULL DEFAULT 'present' CHECK (status IN ('present','absent','late','half_day','holiday','leave')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "att_select" ON attendance; CREATE POLICY "att_select" ON attendance FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "att_insert" ON attendance; CREATE POLICY "att_insert" ON attendance FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "att_update" ON attendance; CREATE POLICY "att_update" ON attendance FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "att_delete" ON attendance; CREATE POLICY "att_delete" ON attendance FOR DELETE TO authenticated USING (true);

-- ============================================================
-- ONLINE ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS online_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  order_number text NOT NULL,
  customer_name text NOT NULL,
  customer_email text,
  customer_phone text NOT NULL,
  customer_address text NOT NULL,
  customer_city text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','confirmed','processing','shipped','delivered','cancelled','refunded')),
  payment_method text NOT NULL DEFAULT 'cod',
  payment_status text NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending','paid','failed','refunded')),
  subtotal decimal(15,2) NOT NULL DEFAULT 0,
  shipping_cost decimal(15,2) NOT NULL DEFAULT 0,
  discount_amount decimal(15,2) NOT NULL DEFAULT 0,
  total_amount decimal(15,2) NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS oo_tenant_num ON online_orders(tenant_id, order_number);
CREATE INDEX IF NOT EXISTS oo_status ON online_orders(status);

ALTER TABLE online_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "oo_select" ON online_orders; CREATE POLICY "oo_select" ON online_orders FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "oo_insert" ON online_orders; CREATE POLICY "oo_insert" ON online_orders FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "oo_update" ON online_orders; CREATE POLICY "oo_update" ON online_orders FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "oo_delete" ON online_orders; CREATE POLICY "oo_delete" ON online_orders FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS online_order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  online_order_id uuid NOT NULL REFERENCES online_orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id),
  product_name text NOT NULL,
  quantity decimal(15,3) NOT NULL DEFAULT 1,
  unit_price decimal(15,2) NOT NULL DEFAULT 0,
  subtotal decimal(15,2) NOT NULL DEFAULT 0
);

ALTER TABLE online_order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ooi_select" ON online_order_items; CREATE POLICY "ooi_select" ON online_order_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "ooi_insert" ON online_order_items; CREATE POLICY "ooi_insert" ON online_order_items FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "ooi_update" ON online_order_items; CREATE POLICY "ooi_update" ON online_order_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "ooi_delete" ON online_order_items; CREATE POLICY "ooi_delete" ON online_order_items FOR DELETE TO authenticated USING (true);

-- ============================================================
-- WARRANTY
-- ============================================================
CREATE TABLE IF NOT EXISTS warranty_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  warranty_number text NOT NULL,
  product_id uuid NOT NULL REFERENCES products(id),
  customer_id uuid REFERENCES customers(id),
  invoice_id uuid REFERENCES invoices(id),
  purchase_date date NOT NULL,
  expiry_date date NOT NULL,
  serial_number text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','expired','claimed','void')),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE warranty_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "wr_select" ON warranty_records; CREATE POLICY "wr_select" ON warranty_records FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "wr_insert" ON warranty_records; CREATE POLICY "wr_insert" ON warranty_records FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "wr_update" ON warranty_records; CREATE POLICY "wr_update" ON warranty_records FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "wr_delete" ON warranty_records; CREATE POLICY "wr_delete" ON warranty_records FOR DELETE TO authenticated USING (true);

-- ============================================================
-- ACTIVITY LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
  user_id uuid REFERENCES profiles(id),
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid,
  entity_label text,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS logs_created ON activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS logs_user ON activity_logs(user_id);

ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "al_select" ON activity_logs; CREATE POLICY "al_select" ON activity_logs FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "al_insert" ON activity_logs; CREATE POLICY "al_insert" ON activity_logs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "al_update" ON activity_logs; CREATE POLICY "al_update" ON activity_logs FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "al_delete" ON activity_logs; CREATE POLICY "al_delete" ON activity_logs FOR DELETE TO authenticated USING (true);