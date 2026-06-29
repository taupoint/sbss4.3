/*
# SI Building Solutions ERP — Seed Data (Migration 003)

Inserts demo data for all core tables so the dashboard and modules
have realistic data to display from day one.

All UUIDs use only valid hex characters (0-9, a-f).
*/

-- ============================================================
-- WAREHOUSES
-- ============================================================
INSERT INTO warehouses (id, name, code, address, city, is_default) VALUES
  ('11000000-0000-0000-0000-000000000001', 'Main Warehouse', 'WH-MAIN', '123 Industrial Area, Dhaka', 'Dhaka', true),
  ('11000000-0000-0000-0000-000000000002', 'Showroom Store', 'WH-SHOW', '456 Commercial Road, Dhaka', 'Dhaka', false),
  ('11000000-0000-0000-0000-000000000003', 'Chittagong Branch', 'WH-CTG', '789 Port Road, Chittagong', 'Chittagong', false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- CATEGORIES
-- ============================================================
INSERT INTO categories (id, name, slug, sort_order) VALUES
  ('22000000-0000-0000-0000-000000000001', 'Tiles & Ceramics', 'tiles-ceramics', 1),
  ('22000000-0000-0000-0000-000000000002', 'Sanitary Ware', 'sanitary-ware', 2),
  ('22000000-0000-0000-0000-000000000003', 'Electrical', 'electrical', 3),
  ('22000000-0000-0000-0000-000000000004', 'Paints', 'paints', 4),
  ('22000000-0000-0000-0000-000000000005', 'Hardware', 'hardware', 5),
  ('22000000-0000-0000-0000-000000000006', 'Construction Materials', 'construction-materials', 6),
  ('22000000-0000-0000-0000-000000000007', 'Home Improvement', 'home-improvement', 7),
  ('22000000-0000-0000-0000-000000000008', 'Plumbing', 'plumbing', 8)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- BRANDS
-- ============================================================
INSERT INTO brands (id, name, slug, country_of_origin) VALUES
  ('33000000-0000-0000-0000-000000000001', 'RAK Ceramics', 'rak-ceramics', 'UAE'),
  ('33000000-0000-0000-0000-000000000002', 'TOTO', 'toto', 'Japan'),
  ('33000000-0000-0000-0000-000000000003', 'Schneider Electric', 'schneider', 'France'),
  ('33000000-0000-0000-0000-000000000004', 'Berger Paints', 'berger', 'Bangladesh'),
  ('33000000-0000-0000-0000-000000000005', 'Asian Paints', 'asian-paints', 'India'),
  ('33000000-0000-0000-0000-000000000006', 'Grohe', 'grohe', 'Germany'),
  ('33000000-0000-0000-0000-000000000007', 'Philips', 'philips', 'Netherlands'),
  ('33000000-0000-0000-0000-000000000008', 'Crown Cement', 'crown-cement', 'Bangladesh')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PRODUCTS
-- ============================================================
INSERT INTO products (id, sku, name, category_id, brand_id, unit, cost_price, sale_price, min_stock_level, is_online, warranty_months, image_url) VALUES
  ('44000000-0000-0000-0000-000000000001', 'TA-0001', 'RAK Floor Tiles 60x60cm (White)', '22000000-0000-0000-0000-000000000001', '33000000-0000-0000-0000-000000000001', 'sqft', 280, 350, 100, true, 12, 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000002', 'TA-0002', 'RAK Wall Tiles 30x60cm (Beige)', '22000000-0000-0000-0000-000000000001', '33000000-0000-0000-0000-000000000001', 'sqft', 220, 280, 80, true, 12, 'https://images.pexels.com/photos/276583/pexels-photo-276583.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000003', 'TA-0020', 'Tile Adhesive (20kg)', '22000000-0000-0000-0000-000000000006', null, 'bag', 320, 420, 20, false, 0, 'https://images.pexels.com/photos/5691544/pexels-photo-5691544.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000004', 'SW-0001', 'TOTO Close Coupled WC Suite', '22000000-0000-0000-0000-000000000002', '33000000-0000-0000-0000-000000000002', 'set', 8500, 12000, 10, true, 24, 'https://images.pexels.com/photos/1910472/pexels-photo-1910472.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000005', 'SW-0002', 'Grohe Shower System Complete', '22000000-0000-0000-0000-000000000002', '33000000-0000-0000-0000-000000000006', 'set', 15000, 22000, 5, true, 36, 'https://images.pexels.com/photos/2507016/pexels-photo-2507016.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000006', 'EL-0001', 'Schneider 20A Switch (White)', '22000000-0000-0000-0000-000000000003', '33000000-0000-0000-0000-000000000003', 'pcs', 180, 250, 50, true, 12, 'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000007', 'EL-0018', 'LED Panel Light 18W', '22000000-0000-0000-0000-000000000003', '33000000-0000-0000-0000-000000000007', 'pcs', 380, 550, 15, true, 24, 'https://images.pexels.com/photos/577514/pexels-photo-577514.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000008', 'PT-0001', 'Berger Plastic Emulsion (20L)', '22000000-0000-0000-0000-000000000004', '33000000-0000-0000-0000-000000000004', 'tin', 1800, 2400, 30, true, 0, 'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000009', 'PT-0002', 'Asian Paints Exterior (20L)', '22000000-0000-0000-0000-000000000004', '33000000-0000-0000-0000-000000000005', 'tin', 2200, 3000, 20, true, 0, 'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000010', 'HW-0001', 'Heavy Duty Door Lock (SS)', '22000000-0000-0000-0000-000000000005', null, 'pcs', 450, 680, 25, true, 12, 'https://images.pexels.com/photos/279810/pexels-photo-279810.jpeg?w=400'),
  ('44000000-0000-0000-0000-000000000011', 'CM-0001', 'Crown Cement (50kg)', '22000000-0000-0000-0000-000000000006', '33000000-0000-0000-0000-000000000008', 'bag', 480, 580, 200, false, 0, null),
  ('44000000-0000-0000-0000-000000000012', 'WP-0101', 'Water Pump 1HP', '22000000-0000-0000-0000-000000000007', null, 'pcs', 7500, 10500, 10, true, 12, 'https://images.pexels.com/photos/3862365/pexels-photo-3862365.jpeg?w=400')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- INVENTORY ITEMS
-- ============================================================
INSERT INTO inventory_items (product_id, warehouse_id, quantity_on_hand, quantity_reserved) VALUES
  ('44000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-000000000001', 850, 120),
  ('44000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-000000000001', 620, 80),
  ('44000000-0000-0000-0000-000000000003', '11000000-0000-0000-0000-000000000001', 5, 0),
  ('44000000-0000-0000-0000-000000000004', '11000000-0000-0000-0000-000000000001', 24, 3),
  ('44000000-0000-0000-0000-000000000005', '11000000-0000-0000-0000-000000000001', 12, 2),
  ('44000000-0000-0000-0000-000000000006', '11000000-0000-0000-0000-000000000001', 180, 20),
  ('44000000-0000-0000-0000-000000000007', '11000000-0000-0000-0000-000000000001', 3, 0),
  ('44000000-0000-0000-0000-000000000008', '11000000-0000-0000-0000-000000000001', 85, 10),
  ('44000000-0000-0000-0000-000000000009', '11000000-0000-0000-0000-000000000001', 45, 5),
  ('44000000-0000-0000-0000-000000000010', '11000000-0000-0000-0000-000000000001', 65, 8),
  ('44000000-0000-0000-0000-000000000011', '11000000-0000-0000-0000-000000000001', 450, 50),
  ('44000000-0000-0000-0000-000000000012', '11000000-0000-0000-0000-000000000001', 2, 0)
ON CONFLICT DO NOTHING;

-- ============================================================
-- SUPPLIERS
-- ============================================================
INSERT INTO suppliers (id, code, name, company_name, phone, city, credit_limit, credit_days, outstanding_balance, total_purchases) VALUES
  ('55000000-0000-0000-0000-000000000001', 'SUP-001', 'Ahmed Trading', 'Ahmed Trading Co. Ltd.', '01711000001', 'Dhaka', 500000, 30, 185000, 2850000),
  ('55000000-0000-0000-0000-000000000002', 'SUP-002', 'Karim Distributors', 'Karim Distributors Ltd.', '01711000002', 'Dhaka', 300000, 45, 95000, 1200000),
  ('55000000-0000-0000-0000-000000000003', 'SUP-003', 'Chittagong Ceramics', 'Chittagong Ceramics Import', '01811000003', 'Chittagong', 800000, 60, 320000, 4500000),
  ('55000000-0000-0000-0000-000000000004', 'SUP-004', 'National Electricals', 'National Electricals Ltd.', '01911000004', 'Dhaka', 200000, 30, 65000, 980000),
  ('55000000-0000-0000-0000-000000000005', 'SUP-005', 'Paint World BD', 'Paint World Bangladesh', '01711000005', 'Dhaka', 400000, 145000, 145000, 2100000)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- CUSTOMERS
-- ============================================================
INSERT INTO customers (id, code, name, type, company_name, phone, city, credit_limit, credit_days, outstanding_balance, total_purchases) VALUES
  ('00000000-0000-0000-0000-000000000001', 'WALK-IN', 'Walk-in Customer', 'retail', null, null, null, 0, 0, 0, 0),
  ('66000000-0000-0000-0000-000000000001', 'CUS-001', 'ABC Builders', 'builder', 'ABC Builders & Developers', '01711100001', 'Dhaka', 500000, 30, 250000, 3500000),
  ('66000000-0000-0000-0000-000000000002', 'CUS-002', 'Rahman Construction', 'contractor', 'Rahman Construction Co.', '01711100002', 'Dhaka', 300000, 45, 120000, 2500000),
  ('66000000-0000-0000-0000-000000000003', 'CUS-003', 'XYZ Architects', 'architect', 'XYZ Architects & Design', '01811100003', 'Dhaka', 200000, 30, 85000, 1800000),
  ('66000000-0000-0000-0000-000000000004', 'CUS-004', 'Modern Interiors', 'interior_designer', 'Modern Interiors Ltd.', '01911100004', 'Dhaka', 150000, 30, 65000, 1200000),
  ('66000000-0000-0000-0000-000000000005', 'CUS-005', 'Green Builders Ltd.', 'builder', 'Green Builders Ltd.', '01711100005', 'Chittagong', 400000, 60, 45000, 950000),
  ('66000000-0000-0000-0000-000000000006', 'CUS-006', 'City Home Decor', 'retail', 'City Home Decor', '01611100006', 'Dhaka', 50000, 15, 12000, 380000),
  ('66000000-0000-0000-0000-000000000007', 'CUS-007', 'Summit Properties', 'corporate', 'Summit Properties Ltd.', '01511100007', 'Dhaka', 1000000, 60, 350000, 5200000),
  ('66000000-0000-0000-0000-000000000008', 'CUS-008', 'Rahman Enterprise', 'contractor', 'Rahman Enterprise', '01711100008', 'Sylhet', 200000, 30, 85000, 1100000)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- INVOICES
-- ============================================================
INSERT INTO invoices (id, invoice_number, customer_id, status, invoice_date, due_date, subtotal, discount_amount, tax_amount, total_amount, amount_paid, warehouse_id, is_pos) VALUES
  ('77000000-0000-0000-0000-000000000001', 'INV-02458', '66000000-0000-0000-0000-000000000001', 'partially_paid', CURRENT_DATE - 2, CURRENT_DATE + 28, 220000, 5000, 0, 215000, 100000, '11000000-0000-0000-0000-000000000001', false),
  ('77000000-0000-0000-0000-000000000002', 'INV-02457', '66000000-0000-0000-0000-000000000002', 'paid', CURRENT_DATE - 3, CURRENT_DATE + 27, 185000, 0, 0, 185000, 185000, '11000000-0000-0000-0000-000000000001', false),
  ('77000000-0000-0000-0000-000000000003', 'INV-02456', '66000000-0000-0000-0000-000000000003', 'sent', CURRENT_DATE - 5, CURRENT_DATE + 25, 95000, 0, 0, 95000, 0, '11000000-0000-0000-0000-000000000002', false),
  ('77000000-0000-0000-0000-000000000004', 'INV-02455', '66000000-0000-0000-0000-000000000007', 'partially_paid', CURRENT_DATE - 7, CURRENT_DATE + 23, 480000, 20000, 0, 460000, 200000, '11000000-0000-0000-0000-000000000001', false),
  ('77000000-0000-0000-0000-000000000005', 'INV-02454', '66000000-0000-0000-0000-000000000004', 'paid', CURRENT_DATE - 10, CURRENT_DATE + 20, 72000, 2000, 0, 70000, 70000, '11000000-0000-0000-0000-000000000002', true),
  ('77000000-0000-0000-0000-000000000006', 'INV-02453', '66000000-0000-0000-0000-000000000005', 'overdue', CURRENT_DATE - 45, CURRENT_DATE - 15, 130000, 0, 0, 130000, 50000, '11000000-0000-0000-0000-000000000001', false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- QUOTATIONS
-- ============================================================
INSERT INTO quotations (id, quote_number, customer_id, status, issue_date, expiry_date, subtotal, total_amount) VALUES
  ('88000000-0000-0000-0000-000000000001', 'QT-00248', '66000000-0000-0000-0000-000000000001', 'sent', CURRENT_DATE - 3, CURRENT_DATE + 27, 350000, 350000),
  ('88000000-0000-0000-0000-000000000002', 'QT-00247', '66000000-0000-0000-0000-000000000007', 'viewed', CURRENT_DATE - 5, CURRENT_DATE + 25, 520000, 520000),
  ('88000000-0000-0000-0000-000000000003', 'QT-00246', '66000000-0000-0000-0000-000000000002', 'accepted', CURRENT_DATE - 8, CURRENT_DATE + 22, 185000, 185000),
  ('88000000-0000-0000-0000-000000000004', 'QT-00245', '66000000-0000-0000-0000-000000000003', 'draft', CURRENT_DATE - 1, CURRENT_DATE + 29, 95000, 95000),
  ('88000000-0000-0000-0000-000000000005', 'QT-00244', '66000000-0000-0000-0000-000000000004', 'sent', CURRENT_DATE - 10, CURRENT_DATE + 20, 280000, 280000),
  ('88000000-0000-0000-0000-000000000006', 'QT-00243', '66000000-0000-0000-0000-000000000005', 'expired', CURRENT_DATE - 40, CURRENT_DATE - 10, 165000, 165000)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PURCHASE ORDERS
-- ============================================================
INSERT INTO purchase_orders (id, po_number, supplier_id, status, order_date, expected_date, subtotal, total_amount, amount_paid, warehouse_id) VALUES
  ('99000000-0000-0000-0000-000000000001', 'PO-02415', '55000000-0000-0000-0000-000000000001', 'approved', CURRENT_DATE - 2, CURRENT_DATE + 7, 185000, 185000, 0, '11000000-0000-0000-0000-000000000001'),
  ('99000000-0000-0000-0000-000000000002', 'PO-02414', '55000000-0000-0000-0000-000000000003', 'received', CURRENT_DATE - 10, CURRENT_DATE - 3, 320000, 320000, 320000, '11000000-0000-0000-0000-000000000001'),
  ('99000000-0000-0000-0000-000000000003', 'PO-02413', '55000000-0000-0000-0000-000000000004', 'partially_received', CURRENT_DATE - 15, CURRENT_DATE - 5, 95000, 95000, 50000, '11000000-0000-0000-0000-000000000001'),
  ('99000000-0000-0000-0000-000000000004', 'PO-02412', '55000000-0000-0000-0000-000000000005', 'received', CURRENT_DATE - 20, CURRENT_DATE - 12, 240000, 240000, 240000, '11000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PROJECTS
-- ============================================================
INSERT INTO projects (id, project_number, name, customer_id, status, start_date, end_date, estimated_budget, actual_cost, revenue, progress_percent, location, image_url) VALUES
  ('aa000000-0000-0000-0000-000000000001', 'PRJ-001', 'Apartment Project A', '66000000-0000-0000-0000-000000000001', 'active', '2024-01-10', '2024-07-10', 2500000, 1800000, 2800000, 80, 'Gulshan, Dhaka', 'https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?w=400'),
  ('aa000000-0000-0000-0000-000000000002', 'PRJ-002', 'Commercial Tower B', '66000000-0000-0000-0000-000000000007', 'active', '2024-02-15', '2024-09-15', 5000000, 2200000, 0, 50, 'Motijheel, Dhaka', 'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?w=400'),
  ('aa000000-0000-0000-0000-000000000003', 'PRJ-003', 'Villa Project C', '66000000-0000-0000-0000-000000000003', 'completed', '2024-03-05', '2024-06-05', 1800000, 1750000, 2100000, 100, 'Baridhara, Dhaka', 'https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?w=400'),
  ('aa000000-0000-0000-0000-000000000004', 'PRJ-004', 'Office Building D', '66000000-0000-0000-0000-000000000007', 'active', '2024-04-20', '2024-12-20', 8000000, 1500000, 0, 30, 'Banani, Dhaka', 'https://images.pexels.com/photos/2102587/pexels-photo-2102587.jpeg?w=400'),
  ('aa000000-0000-0000-0000-000000000005', 'PRJ-005', 'Residential Complex E', '66000000-0000-0000-0000-000000000002', 'planning', '2024-07-01', '2025-06-01', 12000000, 0, 0, 0, 'Dhanmondi, Dhaka', 'https://images.pexels.com/photos/1643383/pexels-photo-1643383.jpeg?w=400'),
  ('aa000000-0000-0000-0000-000000000006', 'PRJ-006', 'Hotel Renovation F', '66000000-0000-0000-0000-000000000005', 'on_hold', '2024-05-01', '2024-11-01', 3500000, 800000, 0, 25, 'Chittagong', 'https://images.pexels.com/photos/261102/pexels-photo-261102.jpeg?w=400')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- DELIVERIES
-- ============================================================
INSERT INTO deliveries (id, delivery_number, invoice_id, customer_id, status, delivery_date, delivery_address, delivery_city) VALUES
  ('bb000000-0000-0000-0000-000000000001', 'DLV-00234', '77000000-0000-0000-0000-000000000002', '66000000-0000-0000-0000-000000000002', 'delivered', CURRENT_DATE - 1, 'Rahman Construction Site, Mirpur', 'Dhaka'),
  ('bb000000-0000-0000-0000-000000000002', 'DLV-00233', '77000000-0000-0000-0000-000000000001', '66000000-0000-0000-0000-000000000001', 'in_transit', CURRENT_DATE, 'ABC Builders Site, Gulshan', 'Dhaka'),
  ('bb000000-0000-0000-0000-000000000003', 'DLV-00232', '77000000-0000-0000-0000-000000000005', '66000000-0000-0000-0000-000000000004', 'delivered', CURRENT_DATE - 3, 'Modern Interiors, Banani', 'Dhaka'),
  ('bb000000-0000-0000-0000-000000000004', 'DLV-00231', null, '66000000-0000-0000-0000-000000000007', 'pending', CURRENT_DATE + 2, 'Summit Properties, Motijheel', 'Dhaka'),
  ('bb000000-0000-0000-0000-000000000005', 'DLV-00230', null, '66000000-0000-0000-0000-000000000003', 'pending', CURRENT_DATE + 1, 'XYZ Architects Office, Dhanmondi', 'Dhaka'),
  ('bb000000-0000-0000-0000-000000000006', 'DLV-00229', null, '66000000-0000-0000-0000-000000000005', 'assigned', CURRENT_DATE + 3, 'Green Builders, Chittagong', 'Chittagong'),
  ('bb000000-0000-0000-0000-000000000007', 'DLV-00228', null, '66000000-0000-0000-0000-000000000002', 'in_transit', CURRENT_DATE, 'Rahman Site 2, Uttara', 'Dhaka'),
  ('bb000000-0000-0000-0000-000000000008', 'DLV-00227', null, '66000000-0000-0000-0000-000000000001', 'delivered', CURRENT_DATE - 2, 'ABC Site 2, Bashundhara', 'Dhaka'),
  ('bb000000-0000-0000-0000-000000000009', 'DLV-00226', null, '66000000-0000-0000-0000-000000000006', 'failed', CURRENT_DATE - 1, 'City Home, Elephant Road', 'Dhaka')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ACCOUNTS (Chart of Accounts)
-- ============================================================
INSERT INTO accounts (id, code, name, account_type, is_cash, is_bank) VALUES
  ('cc000000-0000-0000-0000-000000000001', '1000', 'Cash & Bank', 'asset', false, false),
  ('cc000000-0000-0000-0000-000000000002', '1001', 'Cash in Hand', 'asset', true, false),
  ('cc000000-0000-0000-0000-000000000003', '1002', 'Dhaka Bank Current A/C', 'asset', false, true),
  ('cc000000-0000-0000-0000-000000000004', '1100', 'Accounts Receivable', 'asset', false, false),
  ('cc000000-0000-0000-0000-000000000005', '1200', 'Inventory Asset', 'asset', false, false),
  ('cc000000-0000-0000-0000-000000000006', '2000', 'Accounts Payable', 'liability', false, false),
  ('cc000000-0000-0000-0000-000000000007', '3000', 'Owner Equity', 'equity', false, false),
  ('cc000000-0000-0000-0000-000000000008', '4000', 'Sales Revenue', 'revenue', false, false),
  ('cc000000-0000-0000-0000-000000000009', '4100', 'Service Revenue', 'revenue', false, false),
  ('cc000000-0000-0000-0000-000000000010', '5000', 'Cost of Goods Sold', 'expense', false, false),
  ('cc000000-0000-0000-0000-000000000011', '5100', 'Salaries & Wages', 'expense', false, false),
  ('cc000000-0000-0000-0000-000000000012', '5200', 'Rent Expense', 'expense', false, false),
  ('cc000000-0000-0000-0000-000000000013', '5300', 'Utilities', 'expense', false, false),
  ('cc000000-0000-0000-0000-000000000014', '5400', 'Marketing & Advertising', 'expense', false, false),
  ('cc000000-0000-0000-0000-000000000015', '5500', 'Transport & Delivery', 'expense', false, false)
ON CONFLICT (id) DO NOTHING;

UPDATE accounts SET balance = 285000 WHERE id = 'cc000000-0000-0000-0000-000000000002';
UPDATE accounts SET balance = 4850000 WHERE id = 'cc000000-0000-0000-0000-000000000003';
UPDATE accounts SET balance = 1250000 WHERE id = 'cc000000-0000-0000-0000-000000000004';
UPDATE accounts SET balance = 18540000 WHERE id = 'cc000000-0000-0000-0000-000000000005';
UPDATE accounts SET balance = 780000 WHERE id = 'cc000000-0000-0000-0000-000000000006';

-- ============================================================
-- EMPLOYEES
-- ============================================================
INSERT INTO employees (id, employee_id, full_name, designation, department, join_date, salary, status) VALUES
  ('dd000000-0000-0000-0000-000000000001', 'EMP-001', 'Md. Rafiqul Islam', 'Sales Manager', 'Sales', '2020-01-15', 45000, 'active'),
  ('dd000000-0000-0000-0000-000000000002', 'EMP-002', 'Nasrin Akter', 'Senior Sales Executive', 'Sales', '2021-03-10', 28000, 'active'),
  ('dd000000-0000-0000-0000-000000000003', 'EMP-003', 'Karim Uddin', 'Inventory Manager', 'Warehouse', '2019-06-20', 35000, 'active'),
  ('dd000000-0000-0000-0000-000000000004', 'EMP-004', 'Sumaiya Begum', 'Accountant', 'Finance', '2022-01-05', 30000, 'active'),
  ('dd000000-0000-0000-0000-000000000005', 'EMP-005', 'Rahim Ali', 'Delivery Driver', 'Logistics', '2020-09-15', 18000, 'active'),
  ('dd000000-0000-0000-0000-000000000006', 'EMP-006', 'Fatema Khatun', 'Sales Executive', 'Sales', '2022-07-01', 22000, 'active'),
  ('dd000000-0000-0000-0000-000000000007', 'EMP-007', 'Jamal Hossain', 'Delivery Driver', 'Logistics', '2021-11-20', 18000, 'active'),
  ('dd000000-0000-0000-0000-000000000008', 'EMP-008', 'Roksana Parvin', 'HR Manager', 'HR', '2023-02-10', 38000, 'active')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ONLINE ORDERS
-- ============================================================
INSERT INTO online_orders (id, order_number, customer_name, customer_phone, customer_address, customer_city, status, payment_method, payment_status, subtotal, shipping_cost, total_amount) VALUES
  ('ee000000-0000-0000-0000-000000000001', 'WEB-00036', 'Imran Hossain', '01711200001', 'House 12, Road 5, Dhanmondi', 'Dhaka', 'delivered', 'bkash', 'paid', 3500, 100, 3600),
  ('ee000000-0000-0000-0000-000000000002', 'WEB-00035', 'Shirin Akter', '01811200002', 'Flat 3B, Bashundhara', 'Dhaka', 'shipped', 'cod', 'pending', 2800, 100, 2900),
  ('ee000000-0000-0000-0000-000000000003', 'WEB-00034', 'Mahbub Rahman', '01911200003', '45 New Market, Chittagong', 'Chittagong', 'processing', 'nagad', 'paid', 12000, 200, 12200),
  ('ee000000-0000-0000-0000-000000000004', 'WEB-00033', 'Dilara Begum', '01611200004', 'Mirpur DOHS, Block A', 'Dhaka', 'confirmed', 'cod', 'pending', 5500, 100, 5600),
  ('ee000000-0000-0000-0000-000000000005', 'WEB-00032', 'Tanvir Ahmed', '01511200005', 'Sylhet City Center', 'Sylhet', 'pending', 'bkash', 'pending', 8900, 300, 9200),
  ('ee000000-0000-0000-0000-000000000006', 'WEB-00031', 'Poly Akter', '01711200006', 'Uttara Sector 7', 'Dhaka', 'delivered', 'bank_transfer', 'paid', 15600, 200, 15800)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ACTIVITY LOGS
-- ============================================================
INSERT INTO activity_logs (action, entity_type, entity_id, entity_label, created_at) VALUES
  ('created', 'invoice', '77000000-0000-0000-0000-000000000001', 'New sale invoice #INV-02458 created', now() - interval '10 minutes'),
  ('payment_received', 'invoice', '77000000-0000-0000-0000-000000000002', 'Payment received from ABC Builders', now() - interval '20 minutes'),
  ('approved', 'purchase_order', '99000000-0000-0000-0000-000000000001', 'Purchase order #PO-02415 approved', now() - interval '1 hour'),
  ('delivered', 'delivery', 'bb000000-0000-0000-0000-000000000001', 'Delivery #DLV-00234 delivered', now() - interval '2 hours'),
  ('stock_added', 'product', '44000000-0000-0000-0000-000000000008', 'Stock added for 15 items', now() - interval '3 hours'),
  ('created', 'quotation', '88000000-0000-0000-0000-000000000001', 'Quotation #QT-00248 created for ABC Builders', now() - interval '4 hours'),
  ('updated', 'project', 'aa000000-0000-0000-0000-000000000001', 'Project Apartment A progress updated to 80%', now() - interval '5 hours'),
  ('new_order', 'online_order', 'ee000000-0000-0000-0000-000000000005', 'New online order #WEB-00032 received', now() - interval '6 hours')
ON CONFLICT DO NOTHING;