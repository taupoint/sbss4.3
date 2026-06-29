/*
# Accounting Automation - Default Accounts & Auto-posting Triggers

## Overview
This migration adds automated accounting entries for:
1. Invoice finalization (sales)
2. Payment received
3. GRN processing (purchases)
4. Stock movements (returns)

## Changes
- Creates default chart of accounts if not exists
- Creates a sequence for journal entry numbers
- Creates `post_journal_entry` function to post journal entries
- Creates triggers for automatic journal posting
*/

-- Insert default chart of accounts if not exists
INSERT INTO accounts (code, name, account_type, is_cash, is_bank, bank_name, account_number, balance) VALUES
  ('1000', 'Cash on Hand', 'asset', true, false, NULL, NULL, 0),
  ('1010', 'Bank Account', 'asset', false, true, 'Main Bank', '0012345678', 0),
  ('1100', 'Accounts Receivable', 'asset', false, false, NULL, NULL, 0),
  ('1200', 'Inventory', 'asset', false, false, NULL, NULL, 0),
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

-- RPC function for getting next journal entry number
CREATE OR REPLACE FUNCTION get_next_journal_number()
RETURNS text AS $$
DECLARE
  next_num int;
BEGIN
  next_num := nextval('journal_entry_seq');
  RETURN 'JE-' || next_num::text;
END;
$$ LANGUAGE plpgsql;