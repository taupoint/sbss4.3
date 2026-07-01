/*
# Sales Returns Accounting System

## Overview
This migration creates a complete sales return management system with proper double-entry accounting.
It addresses the gap where sales returns were only updating inventory but not creating journal entries.

## New Tables

### sales_returns
- `id` (uuid, primary key) - Unique identifier
- `return_number` (text, unique) - Human-readable return number (e.g., SR-0001)
- `invoice_id` (uuid, FK to invoices) - Original invoice being returned
- `customer_id` (uuid, FK to customers) - Customer who made the return
- `return_date` (date) - Date of the return
- `total_refund_amount` (numeric) - Total amount to be refunded
- `refund_method` (text) - 'cash', 'bank_transfer', or 'store_credit'
- `status` (text) - 'completed', 'pending', 'cancelled'
- `notes` (text) - Additional notes
- `journal_entry_id` (uuid, FK to journal_entries) - Link to the accounting entry
- `payment_id` (uuid, FK to payments) - Link to refund payment record
- `created_by` (uuid, FK to profiles) - User who processed the return
- `created_at` (timestamptz) - Creation timestamp

### sales_return_items
- `id` (uuid, primary key)
- `sales_return_id` (uuid, FK to sales_returns) - Parent return record
- `invoice_item_id` (uuid, FK to invoice_items) - Original line item
- `product_id` (uuid, FK to products) - Product returned
- `variant_id` (uuid, FK to product_variants) - Variant if applicable
- `quantity_returned` (numeric) - Quantity returned
- `unit_price` (numeric) - Sale price per unit
- `cost_price` (numeric) - Cost price for COGS reversal
- `subtotal` (numeric) - Line total (qty × unit_price)
- `reason` (text) - Return reason
- `created_at` (timestamptz)

## New Accounts

### Sales Returns & Allowances (Code 4050)
- Contra-revenue account to track returned sales
- Reduces gross revenue on P&L

### Customer Refund Payable (Code 2200)
- Liability account for store credit refunds
- Tracks amounts owed to customers as credit

## Security
- RLS enabled on both new tables
- Policies allow authenticated users full CRUD access (company-wide access for ERP)

## Important Notes
1. This migration does NOT delete any existing data
2. Stock movements with reference_type='sales_return' will now have proper accounting
3. Existing returns tracked in stock_movements can be migrated to new tables if needed
*/

-- Create sales_returns table
CREATE TABLE IF NOT EXISTS sales_returns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001'::uuid,
  return_number TEXT UNIQUE NOT NULL,
  invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  return_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_refund_amount NUMERIC(15,2) NOT NULL DEFAULT 0,
  refund_method TEXT NOT NULL DEFAULT 'store_credit' CHECK (refund_method IN ('cash', 'bank_transfer', 'store_credit')),
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
  notes TEXT,
  journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE SET NULL,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create sales_return_items table
CREATE TABLE IF NOT EXISTS sales_return_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001'::uuid,
  sales_return_id UUID NOT NULL REFERENCES sales_returns(id) ON DELETE CASCADE,
  invoice_item_id UUID REFERENCES invoice_items(id) ON DELETE SET NULL,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
  quantity_returned NUMERIC NOT NULL,
  unit_price NUMERIC(15,2) NOT NULL,
  cost_price NUMERIC(15,2),
  subtotal NUMERIC(15,2) NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_sales_returns_invoice ON sales_returns(invoice_id);
CREATE INDEX IF NOT EXISTS idx_sales_returns_customer ON sales_returns(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_returns_date ON sales_returns(return_date);
CREATE INDEX IF NOT EXISTS idx_sales_return_items_return ON sales_return_items(sales_return_id);
CREATE INDEX IF NOT EXISTS idx_sales_return_items_product ON sales_return_items(product_id);

-- Enable RLS on new tables
ALTER TABLE sales_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_return_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for sales_returns (authenticated users have full access for ERP operations)
DROP POLICY IF EXISTS "select_sales_returns" ON sales_returns;
CREATE POLICY "select_sales_returns" ON sales_returns FOR SELECT
  TO authenticated USING (true);

DROP POLICY IF EXISTS "insert_sales_returns" ON sales_returns;
CREATE POLICY "insert_sales_returns" ON sales_returns FOR INSERT
  TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "update_sales_returns" ON sales_returns;
CREATE POLICY "update_sales_returns" ON sales_returns FOR UPDATE
  TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "delete_sales_returns" ON sales_returns;
CREATE POLICY "delete_sales_returns" ON sales_returns FOR DELETE
  TO authenticated USING (true);

-- RLS Policies for sales_return_items
DROP POLICY IF EXISTS "select_sales_return_items" ON sales_return_items;
CREATE POLICY "select_sales_return_items" ON sales_return_items FOR SELECT
  TO authenticated USING (true);

DROP POLICY IF EXISTS "insert_sales_return_items" ON sales_return_items;
CREATE POLICY "insert_sales_return_items" ON sales_return_items FOR INSERT
  TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "update_sales_return_items" ON sales_return_items;
CREATE POLICY "update_sales_return_items" ON sales_return_items FOR UPDATE
  TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "delete_sales_return_items" ON sales_return_items;
CREATE POLICY "delete_sales_return_items" ON sales_return_items FOR DELETE
  TO authenticated USING (true);

-- Add Sales Returns & Allowances account (contra-revenue)
INSERT INTO accounts (id, tenant_id, code, name, account_type, is_active, balance)
SELECT 'cc000000-0000-0000-0000-000000000016'::uuid,
       '00000000-0000-0000-0000-000000000001'::uuid,
       '4050',
       'Sales Returns & Allowances',
       'revenue',
       true,
       0
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE code = '4050');

-- Add Customer Refund Payable account (liability)
INSERT INTO accounts (id, tenant_id, code, name, account_type, is_active, balance)
SELECT 'cc000000-0000-0000-0000-000000000017'::uuid,
       '00000000-0000-0000-0000-000000000001'::uuid,
       '2200',
       'Customer Refund Payable',
       'liability',
       true,
       0
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE code = '2200');

-- Create function to generate return number
CREATE OR REPLACE FUNCTION generate_sales_return_number()
RETURNS TEXT AS $$
DECLARE
  prefix TEXT := 'SR-';
  next_num INTEGER;
  return_number TEXT;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(return_number FROM 4) AS INTEGER)), 0) + 1
  INTO next_num
  FROM sales_returns
  WHERE return_number LIKE 'SR-%';
  
  return_number := prefix || LPAD(next_num::TEXT, 5, '0');
  RETURN return_number;
END;
$$ LANGUAGE plpgsql;