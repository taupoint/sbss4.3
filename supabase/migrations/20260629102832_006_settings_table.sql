/*
# App Settings Table (Migration 006)

1. New Tables
- `app_settings` — Application-wide configuration settings
  - `setting_key` — Unique identifier for the setting
  - `setting_value` — JSON object containing the setting data
  - `updated_at` — Timestamp of last update
  - `updated_by` — User who last updated the setting

2. Security
- RLS enabled on `app_settings`
- Authenticated users can read all settings
- Authenticated users can insert and update settings

3. Default Data
- `company` — Company information (name, license, contact details, currency)
- `notifications` — Notification preferences for various events
- `appearance` — UI appearance settings (dark mode, theme color, interface type)
*/

-- Settings table for application-wide configuration
CREATE TABLE IF NOT EXISTS app_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key text NOT NULL UNIQUE,
  setting_value jsonb NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id)
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "settings_select" ON app_settings;
CREATE POLICY "settings_select" ON app_settings FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "settings_insert" ON app_settings;
CREATE POLICY "settings_insert" ON app_settings FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "settings_update" ON app_settings;
CREATE POLICY "settings_update" ON app_settings FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- Insert default settings
INSERT INTO app_settings (setting_key, setting_value) VALUES
  ('company', '{"name": "SI Building Solutions", "license": "TRAD-2024-001234", "phone": "+880 1711-000000", "email": "info@sibuilding.com", "address": "123 Industrial Area, Dhaka, Bangladesh", "currency": "BDT", "dateFormat": "DD/MM/YYYY"}'),
  ('notifications', '{"lowStock": true, "newOrders": true, "paymentReceived": true, "overdueInvoices": false, "deliveryUpdates": true, "poApprovals": true}'),
  ('appearance', '{"darkMode": false, "theme": "#2563eb", "interface": "desktop"}')
ON CONFLICT (setting_key) DO NOTHING;