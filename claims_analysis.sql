-- ============================================================
--  CLAIMS DATA REVIEW & REPORTING — SQL ANALYSIS SCRIPT
--  Financial / Billing Claims
--  Generated: 2026-05-20
-- ============================================================

-- ============================================================
-- SECTION 1: TABLE CREATION & MOCK DATA LOAD
-- ============================================================

-- Drop tables if they exist (for re-runs)
DROP TABLE IF EXISTS claim_line_items;
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS providers;
DROP TABLE IF EXISTS payers;

-- Payers (insurance companies / clients paying the bills)
CREATE TABLE payers (
    payer_id       INTEGER PRIMARY KEY,
    payer_name     TEXT NOT NULL,
    payer_type     TEXT NOT NULL   -- e.g. 'Commercial', 'Government', 'Self-Pay'
);

-- Providers (vendors / service providers submitting claims)
CREATE TABLE providers (
    provider_id    INTEGER PRIMARY KEY,
    provider_name  TEXT NOT NULL,
    provider_type  TEXT NOT NULL,  -- e.g. 'Hospital', 'Clinic', 'Vendor'
    region         TEXT NOT NULL
);

-- Claims master table
CREATE TABLE claims (
    claim_id         TEXT PRIMARY KEY,
    provider_id      INTEGER REFERENCES providers(provider_id),
    payer_id         INTEGER REFERENCES payers(payer_id),
    claim_date       DATE NOT NULL,
    due_date         DATE NOT NULL,
    payment_date     DATE,          -- NULL if unpaid
    status           TEXT NOT NULL, -- 'Paid', 'Pending', 'Denied', 'Disputed'
    claim_amount     NUMERIC(12,2) NOT NULL,
    approved_amount  NUMERIC(12,2),
    paid_amount      NUMERIC(12,2),
    denial_reason    TEXT,
    aging_bucket     TEXT           -- '0-30', '31-60', '61-90', '90+'
);

-- Claim line items (individual billing codes per claim)
CREATE TABLE claim_line_items (
    line_id       INTEGER PRIMARY KEY,
    claim_id      TEXT REFERENCES claims(claim_id),
    service_code  TEXT NOT NULL,
    description   TEXT NOT NULL,
    quantity      INTEGER NOT NULL DEFAULT 1,
    unit_price    NUMERIC(10,2) NOT NULL,
    line_total    NUMERIC(10,2) NOT NULL
);

-- ============================================================
-- INSERT MOCK DATA
-- ============================================================

INSERT INTO payers VALUES
    (1, 'BlueCross BlueShield', 'Commercial'),
    (2, 'Aetna Financial',      'Commercial'),
    (3, 'CMS Medicare',         'Government'),
    (4, 'State Medicaid',       'Government'),
    (5, 'Self-Pay Client',      'Self-Pay');

INSERT INTO providers VALUES
    (101, 'Metro General Hospital',  'Hospital', 'North'),
    (102, 'Sunrise Clinic',          'Clinic',   'South'),
    (103, 'TechMed Supplies Ltd',    'Vendor',   'East'),
    (104, 'CareFirst Diagnostics',   'Clinic',   'West'),
    (105, 'Allied Health Services',  'Hospital', 'North');

INSERT INTO claims VALUES
    ('CLM-0001', 101, 1, '2026-01-05', '2026-02-04', '2026-02-01', 'Paid',     12500.00, 12000.00, 12000.00, NULL,                   '0-30'),
    ('CLM-0002', 102, 2, '2026-01-10', '2026-02-09', '2026-02-15', 'Paid',      4750.00,  4750.00,  4750.00, NULL,                   '0-30'),
    ('CLM-0003', 103, 3, '2026-01-15', '2026-02-14', NULL,         'Pending',   8200.00,  8200.00,      NULL, NULL,                   '31-60'),
    ('CLM-0004', 104, 1, '2026-01-20', '2026-02-19', NULL,         'Denied',    3300.00,     0.00,      NULL, 'Not Covered',          '31-60'),
    ('CLM-0005', 105, 4, '2026-01-25', '2026-02-24', NULL,         'Disputed',  6800.00,  5000.00,      NULL, 'Amount Disagreement',  '31-60'),
    ('CLM-0006', 101, 2, '2026-02-01', '2026-03-03', '2026-03-01', 'Paid',     15000.00, 14500.00, 14500.00, NULL,                   '0-30'),
    ('CLM-0007', 102, 5, '2026-02-05', '2026-03-07', NULL,         'Pending',   2100.00,  2100.00,      NULL, NULL,                   '0-30'),
    ('CLM-0008', 103, 3, '2026-02-10', '2026-03-12', NULL,         'Pending',   9400.00,  9400.00,      NULL, NULL,                   '0-30'),
    ('CLM-0009', 104, 4, '2026-02-14', '2026-03-16', NULL,         'Denied',    5500.00,     0.00,      NULL, 'Duplicate Claim',      '0-30'),
    ('CLM-0010', 105, 1, '2026-02-20', '2026-03-22', '2026-03-20', 'Paid',     11200.00, 11200.00, 11200.00, NULL,                   '0-30'),
    ('CLM-0011', 101, 3, '2026-03-01', '2026-03-31', NULL,         'Pending',  17800.00, 17800.00,      NULL, NULL,                   '0-30'),
    ('CLM-0012', 102, 2, '2026-03-05', '2026-04-04', NULL,         'Disputed',  4200.00,  3800.00,      NULL, 'Missing Documentation','0-30'),
    ('CLM-0013', 103, 1, '2025-11-01', '2025-12-01', NULL,         'Pending',   6600.00,  6600.00,      NULL, NULL,                   '90+'),
    ('CLM-0014', 104, 2, '2025-11-15', '2025-12-15', NULL,         'Disputed',  3900.00,  3500.00,      NULL, 'Amount Disagreement',  '90+'),
    ('CLM-0015', 105, 5, '2025-12-01', '2025-12-31', NULL,         'Denied',    7700.00,     0.00,      NULL, 'Policy Lapsed',        '61-90');

INSERT INTO claim_line_items VALUES
    (1,  'CLM-0001', 'SVC-001', 'Inpatient Room & Board',      5, 1500.00,  7500.00),
    (2,  'CLM-0001', 'SVC-002', 'ICU Monitoring',              1, 5000.00,  5000.00),
    (3,  'CLM-0002', 'SVC-003', 'Consultation Fee',            2,  750.00,  1500.00),
    (4,  'CLM-0002', 'SVC-004', 'Diagnostic Tests',            1, 3250.00,  3250.00),
    (5,  'CLM-0003', 'SVC-005', 'Medical Supplies',           20,  200.00,  4000.00),
    (6,  'CLM-0003', 'SVC-006', 'Equipment Rental',            3,  900.00,  2700.00),
    (7,  'CLM-0003', 'SVC-007', 'Delivery & Logistics',        1, 1500.00,  1500.00),
    (8,  'CLM-0004', 'SVC-008', 'Specialist Visit',            3,  550.00,  1650.00),
    (9,  'CLM-0004', 'SVC-009', 'Lab Tests',                   2,  825.00,  1650.00),
    (10, 'CLM-0005', 'SVC-010', 'Surgery Fee',                 1, 5000.00,  5000.00),
    (11, 'CLM-0005', 'SVC-011', 'Anesthesia',                  1, 1800.00,  1800.00),
    (12, 'CLM-0006', 'SVC-001', 'Inpatient Room & Board',      6, 1500.00,  9000.00),
    (13, 'CLM-0006', 'SVC-012', 'Physical Therapy',            5,  700.00,  3500.00),
    (14, 'CLM-0006', 'SVC-002', 'ICU Monitoring',              1, 2500.00,  2500.00),
    (15, 'CLM-0007', 'SVC-003', 'Consultation Fee',            1,  750.00,   750.00),
    (16, 'CLM-0007', 'SVC-013', 'Prescription Billing',        3,  450.00,  1350.00),
    (17, 'CLM-0008', 'SVC-005', 'Medical Supplies',           30,  180.00,  5400.00),
    (18, 'CLM-0008', 'SVC-006', 'Equipment Rental',            4,  900.00,  3600.00),
    (19, 'CLM-0008', 'SVC-007', 'Delivery & Logistics',        1,  400.00,   400.00),
    (20, 'CLM-0009', 'SVC-008', 'Specialist Visit',            2,  550.00,  1100.00),
    (21, 'CLM-0009', 'SVC-004', 'Diagnostic Tests',            2, 1700.00,  3400.00),
    (22, 'CLM-0010', 'SVC-010', 'Surgery Fee',                 1, 8000.00,  8000.00),
    (23, 'CLM-0010', 'SVC-011', 'Anesthesia',                  1, 2000.00,  2000.00),
    (24, 'CLM-0010', 'SVC-014', 'Post-Op Care',                2,  600.00,  1200.00),
    (25, 'CLM-0011', 'SVC-001', 'Inpatient Room & Board',      7, 1500.00, 10500.00),
    (26, 'CLM-0011', 'SVC-002', 'ICU Monitoring',              1, 5000.00,  5000.00),
    (27, 'CLM-0011', 'SVC-015', 'Specialist Consultation',     1, 2300.00,  2300.00),
    (28, 'CLM-0012', 'SVC-003', 'Consultation Fee',            2,  750.00,  1500.00),
    (29, 'CLM-0012', 'SVC-004', 'Diagnostic Tests',            1, 2700.00,  2700.00),
    (30, 'CLM-0013', 'SVC-005', 'Medical Supplies',           15,  200.00,  3000.00),
    (31, 'CLM-0013', 'SVC-006', 'Equipment Rental',            2,  900.00,  1800.00),
    (32, 'CLM-0013', 'SVC-016', 'Installation Services',       1, 1800.00,  1800.00),
    (33, 'CLM-0014', 'SVC-008', 'Specialist Visit',            2,  550.00,  1100.00),
    (34, 'CLM-0014', 'SVC-017', 'Imaging & Radiology',         1, 2800.00,  2800.00),
    (35, 'CLM-0015', 'SVC-010', 'Surgery Fee',                 1, 5500.00,  5500.00),
    (36, 'CLM-0015', 'SVC-011', 'Anesthesia',                  1, 2200.00,  2200.00);


-- ============================================================
-- SECTION 2: ANALYTICAL QUERIES
-- ============================================================

-- ----------------------------------------------------------
-- Q1: Executive Summary — Total Claims by Status
-- ----------------------------------------------------------
SELECT
    status,
    COUNT(*)                          AS claim_count,
    SUM(claim_amount)                 AS total_billed,
    SUM(approved_amount)              AS total_approved,
    SUM(paid_amount)                  AS total_paid,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_claims
FROM claims
GROUP BY status
ORDER BY total_billed DESC;

-- ----------------------------------------------------------
-- Q2: Claims Aging Report — Outstanding amounts by bucket
-- ----------------------------------------------------------
SELECT
    aging_bucket,
    status,
    COUNT(*)                AS claim_count,
    SUM(claim_amount)       AS total_billed,
    SUM(COALESCE(paid_amount, 0)) AS total_collected,
    SUM(claim_amount) - SUM(COALESCE(paid_amount, 0)) AS outstanding_balance
FROM claims
WHERE status != 'Paid'
GROUP BY aging_bucket, status
ORDER BY
    CASE aging_bucket
        WHEN '90+'   THEN 1
        WHEN '61-90' THEN 2
        WHEN '31-60' THEN 3
        WHEN '0-30'  THEN 4
    END,
    status;

-- ----------------------------------------------------------
-- Q3: Provider Performance — Billing vs. Collections
-- ----------------------------------------------------------
SELECT
    p.provider_name,
    p.provider_type,
    p.region,
    COUNT(c.claim_id)               AS total_claims,
    SUM(c.claim_amount)             AS total_billed,
    SUM(COALESCE(c.paid_amount, 0)) AS total_collected,
    SUM(c.claim_amount) - SUM(COALESCE(c.paid_amount, 0)) AS outstanding,
    ROUND(
        100.0 * SUM(COALESCE(c.paid_amount, 0)) / NULLIF(SUM(c.claim_amount), 0), 1
    )                               AS collection_rate_pct
FROM providers p
JOIN claims c ON p.provider_id = c.provider_id
GROUP BY p.provider_id, p.provider_name, p.provider_type, p.region
ORDER BY total_billed DESC;

-- ----------------------------------------------------------
-- Q4: Payer Analysis — Payment Reliability
-- ----------------------------------------------------------
SELECT
    py.payer_name,
    py.payer_type,
    COUNT(c.claim_id)                        AS total_claims,
    SUM(CASE WHEN c.status = 'Paid'    THEN 1 ELSE 0 END) AS paid_claims,
    SUM(CASE WHEN c.status = 'Denied'  THEN 1 ELSE 0 END) AS denied_claims,
    SUM(CASE WHEN c.status = 'Pending' THEN 1 ELSE 0 END) AS pending_claims,
    SUM(CASE WHEN c.status = 'Disputed'THEN 1 ELSE 0 END) AS disputed_claims,
    SUM(c.claim_amount)                       AS total_billed,
    SUM(COALESCE(c.paid_amount, 0))           AS total_paid,
    ROUND(
        100.0 * SUM(CASE WHEN c.status = 'Denied' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(c.claim_id), 0), 1
    )                                         AS denial_rate_pct
FROM payers py
JOIN claims c ON py.payer_id = c.payer_id
GROUP BY py.payer_id, py.payer_name, py.payer_type
ORDER BY total_billed DESC;

-- ----------------------------------------------------------
-- Q5: Denial Analysis — Reasons & Financial Impact
-- ----------------------------------------------------------
SELECT
    denial_reason,
    COUNT(*)               AS denied_claims,
    SUM(claim_amount)      AS denied_amount,
    ROUND(
        100.0 * SUM(claim_amount) / (SELECT SUM(claim_amount) FROM claims WHERE status = 'Denied'), 1
    )                      AS pct_of_denied_revenue
FROM claims
WHERE status = 'Denied'
GROUP BY denial_reason
ORDER BY denied_amount DESC;

-- ----------------------------------------------------------
-- Q6: Monthly Billing Trend
-- ----------------------------------------------------------
SELECT
    strftime('%Y-%m', claim_date)   AS month,
    COUNT(*)                        AS claims_submitted,
    SUM(claim_amount)               AS total_billed,
    SUM(COALESCE(paid_amount, 0))   AS total_collected,
    SUM(CASE WHEN status = 'Denied' THEN 1 ELSE 0 END) AS denials
FROM claims
GROUP BY month
ORDER BY month;

-- ----------------------------------------------------------
-- Q7: Top Services by Revenue (Line Items)
-- ----------------------------------------------------------
SELECT
    li.service_code,
    li.description,
    COUNT(DISTINCT li.claim_id)     AS claim_count,
    SUM(li.quantity)                AS total_units,
    AVG(li.unit_price)              AS avg_unit_price,
    SUM(li.line_total)              AS total_revenue
FROM claim_line_items li
GROUP BY li.service_code, li.description
ORDER BY total_revenue DESC
LIMIT 10;

-- ----------------------------------------------------------
-- Q8: High-Risk Claims (Large + Unresolved)
-- ----------------------------------------------------------
SELECT
    c.claim_id,
    pr.provider_name,
    py.payer_name,
    c.claim_date,
    c.due_date,
    c.status,
    c.claim_amount,
    c.aging_bucket,
    COALESCE(c.denial_reason, c.status) AS issue
FROM claims c
JOIN providers pr ON c.provider_id = pr.provider_id
JOIN payers   py ON c.payer_id   = py.payer_id
WHERE c.status IN ('Pending', 'Denied', 'Disputed')
  AND c.claim_amount >= 5000
ORDER BY c.claim_amount DESC;

-- ----------------------------------------------------------
-- Q9: Days to Payment Analysis (Paid Claims Only)
-- ----------------------------------------------------------
SELECT
    c.claim_id,
    pr.provider_name,
    py.payer_name,
    c.claim_date,
    c.payment_date,
    CAST(julianday(c.payment_date) - julianday(c.claim_date) AS INTEGER) AS days_to_payment,
    c.claim_amount,
    c.paid_amount
FROM claims c
JOIN providers pr ON c.provider_id = pr.provider_id
JOIN payers   py ON c.payer_id   = py.payer_id
WHERE c.status = 'Paid'
ORDER BY days_to_payment DESC;

-- ----------------------------------------------------------
-- Q10: KPI Summary Dashboard View
-- ----------------------------------------------------------
SELECT
    COUNT(*)                                            AS total_claims,
    SUM(claim_amount)                                   AS total_billed,
    SUM(COALESCE(paid_amount, 0))                       AS total_collected,
    SUM(claim_amount) - SUM(COALESCE(paid_amount, 0))  AS total_outstanding,
    ROUND(100.0 * SUM(COALESCE(paid_amount,0)) / SUM(claim_amount), 1) AS collection_rate_pct,
    SUM(CASE WHEN status = 'Denied'   THEN 1 ELSE 0 END) AS denied_count,
    SUM(CASE WHEN status = 'Pending'  THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN status = 'Disputed' THEN 1 ELSE 0 END) AS disputed_count,
    ROUND(100.0 * SUM(CASE WHEN status='Denied' THEN 1 ELSE 0 END) / COUNT(*), 1) AS denial_rate_pct
FROM claims;
