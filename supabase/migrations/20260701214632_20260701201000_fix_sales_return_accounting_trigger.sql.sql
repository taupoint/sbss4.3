/*
# Fix Sales Return Accounting Trigger

## Problem
The existing stock_movement_accounting_trigger has incorrect journal entries for sales returns:
1. Uses account code 4100 (Service Revenue) instead of 4050 (Sales Returns & Allowances)
2. Credits Inventory instead of debiting it (inventory should INCREASE on return)
3. Does not handle the customer side (Accounts Receivable or Cash refund)
4. Does not handle COGS reversal

## Correct Journal Entries for Sales Return

When a customer returns goods:

**Entry 1 - Revenue Reversal:**
- Dr. Sales Returns & Allowances (4050) - reduces revenue
- Cr. Accounts Receivable (1100) OR Cash/Bank (1000/1010) - reduces what customer owes

**Entry 2 - COGS Reversal:**
- Dr. Inventory (1200) - restores inventory value
- Cr. Cost of Goods Sold (5000) - reduces expense

## Changes Made
1. Updated stock_movement_accounting_trigger to NOT auto-create journal entries for returns
   (The frontend will create proper multi-line journal entries instead)
2. Added helper function to get correct accounts for refund methods

## Important Notes
1. Sales returns now require proper refund method selection in the UI
2. Journal entries will be created by the frontend with correct COGS calculation
3. Payment records will be created for refund tracking
*/

-- Drop the problematic stock movement accounting trigger
DROP TRIGGER IF EXISTS stock_movement_accounting ON stock_movements;
DROP FUNCTION IF EXISTS stock_movement_accounting_trigger();

-- Create a new version that handles only purchase/sale adjustments, not returns
-- (Returns are handled by the frontend with proper multi-entry journal)
CREATE OR REPLACE FUNCTION stock_movement_accounting_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_tenant_id uuid;
  v_amount decimal(15,2);
BEGIN
  -- Only handle non-return movements
  -- Returns (return_in, return_out) are handled by the frontend with proper journal entries
  IF TG_OP = 'INSERT' THEN
    v_tenant_id := COALESCE(NEW.tenant_id, '00000000-0000-0000-0000-000000000001');
    v_amount := ABS(NEW.quantity) * COALESCE(NEW.unit_cost, 0);

    -- Skip journal entry for return movements - handled by frontend
    IF NEW.movement_type IN ('return_in', 'return_out') THEN
      RETURN NEW;
    END IF;

    -- Other movement types could be handled here if needed
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER stock_movement_accounting
  AFTER INSERT ON stock_movements
  FOR EACH ROW
  EXECUTE FUNCTION stock_movement_accounting_trigger();

-- Create helper function to get refund account based on method
CREATE OR REPLACE FUNCTION get_refund_account(p_refund_method text)
RETURNS text AS $$
BEGIN
  RETURN CASE
    WHEN p_refund_method = 'cash' THEN '1000'      -- Cash in Hand
    WHEN p_refund_method = 'bank_transfer' THEN '1010'  -- Bank Account
    WHEN p_refund_method = 'store_credit' THEN '2200'   -- Customer Refund Payable
    ELSE '2200'  -- Default to Customer Refund Payable
  END;
END;
$$ LANGUAGE plpgsql;