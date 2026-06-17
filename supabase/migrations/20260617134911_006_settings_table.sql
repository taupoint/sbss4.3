-- Settings table for application-wide configuration
CREATE TABLE IF NOT EXISTS app_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key text NOT NULL UNIQUE,
  setting_value jsonb NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id)
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "settings_select" ON app_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "settings_insert" ON app_settings FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "settings_update" ON app_settings FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- Insert default settings
INSERT INTO app_settings (setting_key, setting_value) VALUES
  ('company', '{"name": "SI Building Solutions", "license": "TRAD-2024-001234", "phone": "+880 1711-000000", "email": "info@sibuilding.com", "address": "123 Industrial Area, Dhaka, Bangladesh", "currency": "BDT", "dateFormat": "DD/MM/YYYY"}'),
  ('notifications', '{"lowStock": true, "newOrders": true, "paymentReceived": true, "overdueInvoices": false, "deliveryUpdates": true, "poApprovals": true}'),
  ('appearance', '{"darkMode": false, "theme": "#2563eb", "interface": "desktop"}');
