/*
# Fix Sales Returns & Allowances Account Type and Balance

## Problem
Account 4050 (Sales Returns & Allowances) is a contra-revenue account that has a
debit-normal balance (like expense accounts), but was stored with account_type = 'revenue'.
This caused the balance update logic in sales return processing to move the balance
in the wrong direction — debits decreased the balance instead of increasing it.

## Changes
1. Update account 4050's account_type from 'revenue' to 'expense' so that all
   balance update logic across the app correctly treats it as debit-normal.
2. Recalculate account 4050's balance from all posted journal lines (sum of debits
   minus sum of credits), correcting the accumulated error from prior returns.

## Notes
- Contra-revenue accounts behave like expenses for balance purposes: debits increase
  the balance, credits decrease it. Storing as 'expense' makes the existing
  `isDebitAccount = ['asset', 'expense'].includes(account_type)` checks correct.
- On the income statement, this account now appears under expenses, which correctly
  reduces net profit (same mathematical effect as deducting from revenue).
- No data is lost — only the account_type column and balance are updated.
*/

-- Step 1: Recalculate balance for account 4050 from all posted journal lines
-- For a debit-normal (expense) account: balance = sum(debits) - sum(credits)
UPDATE accounts
SET balance = COALESCE((
  SELECT SUM(jl.debit - jl.credit)
  FROM journal_lines jl
  JOIN journal_entries je ON jl.journal_entry_id = je.id
  WHERE jl.account_id = accounts.id
    AND je.is_posted = true
), 0),
    account_type = 'expense'
WHERE code = '4050';
