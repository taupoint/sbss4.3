-- ============================================================
-- ACCOUNTING AUTOMATION - Default Accounts & Auto-posting Triggers
-- ============================================================

-- Insert default chart of accounts if not exists
INSERT INTO accounts (code, name, account_type, is_cash, is_bank, bank_name, account_number, balance) VALUES
  ('1000', 'Cash on Hand', 'asset', true, false, NULL, NULL, 0),
  ('1010', 'Bank Account', 'asset', false, true, 'Main Bank', '0012345678', 0),
  ('1200', 'Accounts Receivable', 'asset', false, false, NULL, NULL, 0),
  ('1300', 'Inventory', 'asset', false, false, NULL, NULL, 0),
  ('2000', 'Accounts Payable', 'liability', false, false, NULL, NULL, 0),
  ('2100', 'VAT Payable', 'liability', false, false, NULL, NULL, 0),
  ('3000', 'Owner Equity', 'equity', false, false, NULL, NULL, 0),
  ('4000', 'Sales Revenue', 'revenue', false, false, NULL, NULL, 0),
  ('4100', 'Sales Returns & Allowances', 'revenue', false, false, NULL, NULL, 0),
  ('4200', 'Discount Given', 'expense', false, false, NULL, NULL, 0),
  ('5000', 'Cost of Goods Sold', 'expense', false, false, NULL, NULL, 0),
  ('5100', 'Purchase Returns', 'expense', false, false, NULL, NULL, 0),
  ('5200', 'Purchase Returns & Allowances', 'revenue', false, false, NULL, NULL, 0),
  ('6000', 'Operating Expenses', 'expense', false, false, NULL, NULL, 0)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Create a sequence for journal entry numbers
CREATE SEQUENCE IF NOT EXISTS journal_entry_seq START 1000;

-- Function to post a journal entry
CREATE OR REPLACE FUNCTION post_journal_entry(
  p_description text,
  p_lines jsonb,
  p_entry_date date DEFAULT CURRENT_DATE,
  p_reference_type text DEFAULT NULL,
  p_reference_id uuid DEFAULT NULL,
  p_tenant_id uuid DEFAULT '00000000-0000-0000-0000-000000000001'
) RETURNS uuid AS $$
DECLARE
  v_entry_id uuid;
  v_entry_number text;
  v_total_debit decimal(15,2) := 0;
  v_total_credit decimal(15,2) := 0;
  v_line jsonb;
  v_account_id uuid;
  v_sort_order int := 0;
BEGIN
  v_entry_number := 'JE-' || nextval('journal_entry_seq')::text;
  
  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    v_total_debit := v_total_debit + COALESCE((v_line->>'debit')::decimal, 0);
    v_total_credit := v_total_credit + COALESCE((v_line->>'credit')::decimal, 0);
  END LOOP;
  
  INSERT INTO journal_entries (
    tenant_id, entry_number, entry_date, description,
    reference_type, reference_id, total_debit, total_credit, is_posted
  ) VALUES (
    p_tenant_id, v_entry_number, p_entry_date, p_description,
    p_reference_type, p_reference_id, v_total_debit, v_total_credit, true
  ) RETURNING id INTO v_entry_id;
  
  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    SELECT id INTO v_account_id FROM accounts WHERE code = (v_line->>'account_code') AND tenant_id = p_tenant_id;
    
    IF v_account_id IS NULL THEN
      RAISE EXCEPTION 'Account not found: %', (v_line->>'account_code');
    END IF;
    
    INSERT INTO journal_lines (
      journal_entry_id, account_id, description, debit, credit, sort_order
    ) VALUES (
      v_entry_id,
      v_account_id,
      v_line->>'description',
      COALESCE((v_line->>'debit')::decimal, 0),
      COALESCE((v_line->>'credit')::decimal, 0),
      v_sort_order
    );
    
    UPDATE accounts SET balance = balance + 
      CASE 
        WHEN account_type IN ('asset', 'expense') THEN 
          COALESCE((v_line->>'debit')::decimal, 0) - COALESCE((v_line->>'credit')::decimal, 0)
        ELSE 
          COALESCE((v_line->>'credit')::decimal, 0) - COALESCE((v_line->>'debit')::decimal, 0)
      END
    WHERE id = v_account_id;
    
    v_sort_order := v_sort_order + 1;
  END LOOP;
  
  RETURN v_entry_id;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: Auto-post journal entry when invoice is finalized
CREATE OR REPLACE FUNCTION invoice_accounting_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_total_amount decimal(15,2);
  v_tenant_id uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.status = 'confirmed' AND OLD.status IN ('draft', 'pending') THEN
    SELECT COALESCE(SUM(quantity * unit_price * (1 + COALESCE(tax_rate, 0)/100.0) - COALESCE(discount, 0)), 0)
    INTO v_total_amount
    FROM invoice_items WHERE invoice_id = NEW.id;
    
    v_tenant_id := COALESCE(NEW.tenant_id, '00000000-0000-0000-0000-000000000001');
    
    IF v_total_amount > 0 THEN
      PERFORM post_journal_entry(
        p_description := 'Invoice #' || NEW.invoice_number || ' - ' || COALESCE(NEW.customer_name, 'Customer'),
        p_lines := jsonb_build_array(
          jsonb_build_object('account_code', '1200', 'debit', v_total_amount, 'description', 'Accounts Receivable'),
          jsonb_build_object('account_code', '4000', 'credit', v_total_amount, 'description', 'Sales Revenue')
        ),
        p_entry_date := NEW.invoice_date,
        p_reference_type := 'invoice',
        p_reference_id := NEW.id,
        p_tenant_id := v_tenant_id
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS invoice_accounting ON invoices;
CREATE TRIGGER invoice_accounting
  AFTER UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION invoice_accounting_trigger();

-- TRIGGER: Auto-post journal entry when payment is received
CREATE OR REPLACE FUNCTION payment_accounting_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_tenant_id uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_tenant_id := COALESCE(NEW.tenant_id, '00000000-0000-0000-0000-000000000001');
    
    PERFORM post_journal_entry(
      p_description := 'Payment received - ' || COALESCE(NEW.payment_method, 'Payment') || ' - Ref: ' || COALESCE(NEW.reference, NEW.id::text),
      p_lines := jsonb_build_array(
        jsonb_build_object('account_code', CASE WHEN NEW.payment_method ILIKE '%bank%' OR NEW.payment_method ILIKE '%transfer%' OR NEW.payment_method ILIKE '%card%' THEN '1010' ELSE '1000' END, 'debit', NEW.amount, 'description', 'Cash/Bank'),
        jsonb_build_object('account_code', '1200', 'credit', NEW.amount, 'description', 'Accounts Receivable')
      ),
      p_entry_date := NEW.payment_date,
      p_reference_type := 'payment',
      p_reference_id := NEW.id,
      p_tenant_id := v_tenant_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_accounting ON payments;
CREATE TRIGGER payment_accounting
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION payment_accounting_trigger();

-- TRIGGER: Auto-post journal entry when GRN is processed
CREATE OR REPLACE FUNCTION grn_accounting_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_total_amount decimal(15,2);
  v_tenant_id uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.status IN ('received', 'completed') AND OLD.status IN ('pending', 'draft') THEN
    SELECT COALESCE(SUM(received_quantity * unit_cost), 0)
    INTO v_total_amount
    FROM grn_items WHERE grn_id = NEW.id;
    
    IF v_total_amount = 0 AND NEW.purchase_order_id IS NOT NULL THEN
      SELECT COALESCE(SUM(poi.quantity * poi.unit_price), 0)
      INTO v_total_amount
      FROM purchase_order_items poi
      WHERE poi.purchase_order_id = NEW.purchase_order_id;
    END IF;
    
    v_tenant_id := COALESCE(NEW.tenant_id, '00000000-0000-0000-0000-000000000001');
    
    IF v_total_amount > 0 THEN
      PERFORM post_journal_entry(
        p_description := 'GRN #' || NEW.grn_number || ' - Goods Received',
        p_lines := jsonb_build_array(
          jsonb_build_object('account_code', '1300', 'debit', v_total_amount, 'description', 'Inventory'),
          jsonb_build_object('account_code', '2000', 'credit', v_total_amount, 'description', 'Accounts Payable')
        ),
        p_entry_date := NEW.grn_date,
        p_reference_type := 'grn',
        p_reference_id := NEW.id,
        p_tenant_id := v_tenant_id
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS grn_accounting ON goods_receipt_notes;
CREATE TRIGGER grn_accounting
  AFTER UPDATE ON goods_receipt_notes
  FOR EACH ROW
  EXECUTE FUNCTION grn_accounting_trigger();

-- TRIGGER: Auto-post journal entry for stock movements (returns)
-- Sales returns: return_in - Debit Sales Returns, Credit Inventory
-- Purchase returns: return_out - Debit Accounts Payable, Credit Inventory
CREATE OR REPLACE FUNCTION stock_movement_accounting_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_tenant_id uuid;
  v_amount decimal(15,2);
  v_ref_type text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_tenant_id := COALESCE(NEW.tenant_id, '00000000-0000-0000-0000-000000000001');
    v_amount := NEW.quantity * COALESCE(NEW.unit_cost, 0);
    
    IF v_amount > 0 THEN
      -- Sales Return (customer returning goods)
      IF NEW.movement_type = 'return_in' THEN
        v_ref_type := 'sales_return';
        PERFORM post_journal_entry(
          p_description := 'Sales Return - ' || COALESCE(NEW.reference_number, NEW.id::text) || ' - ' || COALESCE(NEW.notes, 'Customer Return'),
          p_lines := jsonb_build_array(
            jsonb_build_object('account_code', '4100', 'debit', v_amount, 'description', 'Sales Returns & Allowances'),
            jsonb_build_object('account_code', '1300', 'credit', v_amount, 'description', 'Inventory')
          ),
          p_entry_date := CURRENT_DATE,
          p_reference_type := v_ref_type,
          p_reference_id := NEW.id,
          p_tenant_id := v_tenant_id
        );
      -- Purchase Return (returning goods to supplier)
      ELSIF NEW.movement_type = 'return_out' THEN
        v_ref_type := 'purchase_return';
        PERFORM post_journal_entry(
          p_description := 'Purchase Return - ' || COALESCE(NEW.reference_number, NEW.id::text) || ' - ' || COALESCE(NEW.notes, 'Supplier Return'),
          p_lines := jsonb_build_array(
            jsonb_build_object('account_code', '2000', 'debit', v_amount, 'description', 'Accounts Payable'),
            jsonb_build_object('account_code', '1300', 'credit', v_amount, 'description', 'Inventory')
          ),
          p_entry_date := CURRENT_DATE,
          p_reference_type := v_ref_type,
          p_reference_id := NEW.id,
          p_tenant_id := v_tenant_id
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS stock_movement_accounting ON stock_movements;
CREATE TRIGGER stock_movement_accounting
  AFTER INSERT ON stock_movements
  FOR EACH ROW
  EXECUTE FUNCTION stock_movement_accounting_trigger();

-- Comment on reference types
COMMENT ON COLUMN journal_entries.reference_type IS 'Type of source document: invoice, payment, grn, sales_return, purchase_return';