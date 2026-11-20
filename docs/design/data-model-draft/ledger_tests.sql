-- Integration checks for the ledger constraints (run with psql, ON_ERROR_STOP=1).
\set ON_ERROR_STOP 1
SET client_min_messages = notice;

-- Runs a statement, forces deferred triggers, and asserts it fails on the expected constraint.
CREATE OR REPLACE FUNCTION pg_temp.expect_error(p_sql text, p_constraint text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_constraint text; v_message text;
BEGIN
  BEGIN
    EXECUTE p_sql;
    SET CONSTRAINTS ALL IMMEDIATE;
    RAISE EXCEPTION 'NO_ERROR';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME, v_message = MESSAGE_TEXT;
    IF v_message = 'NO_ERROR' THEN
      RAISE EXCEPTION 'FAIL: expected % but statement succeeded', p_constraint;
    END IF;
    IF v_constraint IS DISTINCT FROM p_constraint THEN
      RAISE EXCEPTION 'FAIL: expected %, got % (%)', p_constraint, v_constraint, v_message;
    END IF;
    RAISE NOTICE 'ok  % -> %', p_constraint, v_message;
  END;
END $$;

-- ─── Fixtures ──────────────────────────────────────────────────────────────────
-- ids: 1x workspaces/users, 2x accounts, 3x categories, 4x operations, 5x entries, 6x lines
INSERT INTO "user" (id, email, updated_at) VALUES
  ('00000000-0000-7000-8000-000000000001', 'me@example.com', now());
INSERT INTO workspace (id, name, updated_at) VALUES
  ('10000000-0000-7000-8000-000000000001', 'W1', now()),
  ('10000000-0000-7000-8000-000000000002', 'W2', now());
INSERT INTO membership (workspace_id, user_id, role) VALUES
  ('10000000-0000-7000-8000-000000000001', '00000000-0000-7000-8000-000000000001', 'OWNER');

INSERT INTO account (id, workspace_id, name, kind, currency, tracking_start_date, updated_at) VALUES
  ('20000000-0000-7000-8000-000000000001', '10000000-0000-7000-8000-000000000001', 'SG Checking', 'CHECKING',   'EUR', '2026-09-01', now()),
  ('20000000-0000-7000-8000-000000000002', '10000000-0000-7000-8000-000000000001', 'LEP',         'SAVINGS',    'EUR', '2026-09-01', now()),
  ('20000000-0000-7000-8000-000000000003', '10000000-0000-7000-8000-000000000001', 'PEA',         'INVESTMENT', 'EUR', '2026-09-01', now()),
  ('20000000-0000-7000-8000-000000000009', '10000000-0000-7000-8000-000000000002', 'Other tenant','CHECKING',   'EUR', '2026-09-01', now());

INSERT INTO category (id, workspace_id, name, kind, updated_at) VALUES
  ('30000000-0000-7000-8000-000000000001', '10000000-0000-7000-8000-000000000001', 'Salaries',  'INCOME',  now()),
  ('30000000-0000-7000-8000-000000000002', '10000000-0000-7000-8000-000000000001', 'Groceries', 'EXPENSE', now()),
  ('30000000-0000-7000-8000-000000000003', '10000000-0000-7000-8000-000000000001', 'Health',    'EXPENSE', now()),
  ('30000000-0000-7000-8000-000000000004', '10000000-0000-7000-8000-000000000001', 'Housing',   'EXPENSE', now()),
  ('30000000-0000-7000-8000-000000000005', '10000000-0000-7000-8000-000000000001', 'Leisure',   'EXPENSE', now());

-- Shorthands
\set W1 '''10000000-0000-7000-8000-000000000001'''
\set U  '''00000000-0000-7000-8000-000000000001'''
\set SG '''20000000-0000-7000-8000-000000000001'''
\set LEP '''20000000-0000-7000-8000-000000000002'''
\set PEA '''20000000-0000-7000-8000-000000000003'''

-- Openings (Sept 1st)
BEGIN;
INSERT INTO operation (id, workspace_id, type, created_by, updated_by, updated_at) VALUES
  ('40000000-0000-7000-8000-000000000001', :W1, 'OPENING', :U, :U, now()),
  ('40000000-0000-7000-8000-000000000002', :W1, 'OPENING', :U, :U, now()),
  ('40000000-0000-7000-8000-000000000003', :W1, 'OPENING', :U, :U, now());
INSERT INTO entry (id, workspace_id, operation_id, operation_type, account_id, account_kind, date, amount) VALUES
  ('50000000-0000-7000-8000-000000000001', :W1, '40000000-0000-7000-8000-000000000001', 'OPENING', :SG,  'CHECKING',   '2026-09-01', 1000),
  ('50000000-0000-7000-8000-000000000002', :W1, '40000000-0000-7000-8000-000000000002', 'OPENING', :LEP, 'SAVINGS',    '2026-09-01', 3000),
  ('50000000-0000-7000-8000-000000000003', :W1, '40000000-0000-7000-8000-000000000003', 'OPENING', :PEA, 'INVESTMENT', '2026-09-01', 4030);
COMMIT;

-- October activity
BEGIN;
INSERT INTO operation (id, workspace_id, type, label, is_fixed, created_by, updated_by, updated_at) VALUES
  ('40000000-0000-7000-8000-000000000010', :W1, 'TRANSACTION', 'Salary',      false, :U, :U, now()),
  ('40000000-0000-7000-8000-000000000011', :W1, 'TRANSACTION', 'Supermarket', false, :U, :U, now()),
  ('40000000-0000-7000-8000-000000000012', :W1, 'TRANSACTION', 'Dermatologist', false, :U, :U, now()),
  ('40000000-0000-7000-8000-000000000013', :W1, 'TRANSACTION', 'Rent',        true,  :U, :U, now()),
  ('40000000-0000-7000-8000-000000000014', :W1, 'TRANSACTION', 'CPAM refund', false, :U, :U, now()),
  ('40000000-0000-7000-8000-000000000015', :W1, 'TRANSFER',    'To PEA',      false, :U, :U, now()),
  ('40000000-0000-7000-8000-000000000016', :W1, 'TRANSFER',    'To LEP',      false, :U, :U, now());
INSERT INTO entry (id, workspace_id, operation_id, operation_type, account_id, account_kind, date, amount) VALUES
  ('50000000-0000-7000-8000-000000000010', :W1, '40000000-0000-7000-8000-000000000010', 'TRANSACTION', :SG,  'CHECKING',   '2026-10-02',  2000),
  ('50000000-0000-7000-8000-000000000011', :W1, '40000000-0000-7000-8000-000000000011', 'TRANSACTION', :SG,  'CHECKING',   '2026-10-03',  -93.84),
  ('50000000-0000-7000-8000-000000000012', :W1, '40000000-0000-7000-8000-000000000012', 'TRANSACTION', :SG,  'CHECKING',   '2026-10-05',  -60),
  ('50000000-0000-7000-8000-000000000013', :W1, '40000000-0000-7000-8000-000000000013', 'TRANSACTION', :SG,  'CHECKING',   '2026-10-06',  -610.62),
  ('50000000-0000-7000-8000-000000000014', :W1, '40000000-0000-7000-8000-000000000014', 'TRANSACTION', :SG,  'CHECKING',   '2026-10-20',  45),
  ('50000000-0000-7000-8000-000000000015', :W1, '40000000-0000-7000-8000-000000000015', 'TRANSFER',    :SG,  'CHECKING',   '2026-10-15',  -500),
  ('50000000-0000-7000-8000-000000000016', :W1, '40000000-0000-7000-8000-000000000015', 'TRANSFER',    :PEA, 'INVESTMENT', '2026-10-15',  500),
  -- transfer straddling two months (C14)
  ('50000000-0000-7000-8000-000000000017', :W1, '40000000-0000-7000-8000-000000000016', 'TRANSFER',    :SG,  'CHECKING',   '2026-10-30',  -300),
  ('50000000-0000-7000-8000-000000000018', :W1, '40000000-0000-7000-8000-000000000016', 'TRANSFER',    :LEP, 'SAVINGS',    '2026-11-02',  300);
INSERT INTO line (id, workspace_id, operation_id, operation_type, category_id, amount, position, refund_of_line_id) VALUES
  ('60000000-0000-7000-8000-000000000010', :W1, '40000000-0000-7000-8000-000000000010', 'TRANSACTION', '30000000-0000-7000-8000-000000000001', 2000,    0, NULL),
  ('60000000-0000-7000-8000-000000000011', :W1, '40000000-0000-7000-8000-000000000011', 'TRANSACTION', '30000000-0000-7000-8000-000000000002', -80,     0, NULL),
  ('60000000-0000-7000-8000-000000000012', :W1, '40000000-0000-7000-8000-000000000011', 'TRANSACTION', '30000000-0000-7000-8000-000000000003', -13.84,  1, NULL),
  ('60000000-0000-7000-8000-000000000013', :W1, '40000000-0000-7000-8000-000000000012', 'TRANSACTION', '30000000-0000-7000-8000-000000000003', -60,     0, NULL),
  ('60000000-0000-7000-8000-000000000014', :W1, '40000000-0000-7000-8000-000000000013', 'TRANSACTION', '30000000-0000-7000-8000-000000000004', -610.62, 0, NULL),
  -- partial refund of the dermatologist line, same category (P4)
  ('60000000-0000-7000-8000-000000000015', :W1, '40000000-0000-7000-8000-000000000014', 'TRANSACTION', '30000000-0000-7000-8000-000000000003', 45,      0, '60000000-0000-7000-8000-000000000013');
COMMIT;

\echo '--- rejections'

-- O2: lines do not balance the entry
SELECT pg_temp.expect_error($$
  INSERT INTO operation (id, workspace_id, type, created_by, updated_by, updated_at) VALUES
    ('40000000-0000-7000-8000-0000000000a1', '10000000-0000-7000-8000-000000000001', 'TRANSACTION', '00000000-0000-7000-8000-000000000001', '00000000-0000-7000-8000-000000000001', now());
  INSERT INTO entry VALUES ('50000000-0000-7000-8000-0000000000a1', '10000000-0000-7000-8000-000000000001', '40000000-0000-7000-8000-0000000000a1', 'TRANSACTION', '20000000-0000-7000-8000-000000000001', 'CHECKING', '2026-10-10', -50);
  INSERT INTO line (id, workspace_id, operation_id, operation_type, category_id, amount, position) VALUES ('60000000-0000-7000-8000-0000000000a1', '10000000-0000-7000-8000-000000000001', '40000000-0000-7000-8000-0000000000a1', 'TRANSACTION', '30000000-0000-7000-8000-000000000002', -49.99, 0);
$$, 'operation_structure');

-- O2: transaction without lines
SELECT pg_temp.expect_error($$
  INSERT INTO operation (id, workspace_id, type, created_by, updated_by, updated_at) VALUES
    ('40000000-0000-7000-8000-0000000000a2', '10000000-0000-7000-8000-000000000001', 'TRANSACTION', '00000000-0000-7000-8000-000000000001', '00000000-0000-7000-8000-000000000001', now());
  INSERT INTO entry VALUES ('50000000-0000-7000-8000-0000000000a2', '10000000-0000-7000-8000-000000000001', '40000000-0000-7000-8000-0000000000a2', 'TRANSACTION', '20000000-0000-7000-8000-000000000001', 'CHECKING', '2026-10-10', -50);
$$, 'operation_structure');

-- O2: editing one line of an existing transaction breaks the balance
SELECT pg_temp.expect_error($$
  UPDATE line SET amount = -79 WHERE id = '60000000-0000-7000-8000-000000000011';
$$, 'operation_structure');

-- O3: credit dated before debit
SELECT pg_temp.expect_error($$
  UPDATE entry SET date = '2026-10-29' WHERE id = '50000000-0000-7000-8000-000000000018';
$$, 'operation_structure');

-- O3: unbalanced transfer
SELECT pg_temp.expect_error($$
  UPDATE entry SET amount = 299 WHERE id = '50000000-0000-7000-8000-000000000018';
$$, 'operation_structure');

-- O3: same account on both sides
SELECT pg_temp.expect_error($$
  UPDATE entry SET account_id = '20000000-0000-7000-8000-000000000001', account_kind = 'CHECKING'
   WHERE id = '50000000-0000-7000-8000-000000000018';
$$, 'entry_operation_id_account_id_key');

-- A3: transaction on an investment account
SELECT pg_temp.expect_error($$
  UPDATE entry SET account_id = '20000000-0000-7000-8000-000000000003', account_kind = 'INVESTMENT'
   WHERE id = '50000000-0000-7000-8000-000000000011';
$$, 'entry_transaction_on_cash_account_check');

-- A3: forging the copied account_kind is caught by the composite FK
SELECT pg_temp.expect_error($$
  UPDATE entry SET account_id = '20000000-0000-7000-8000-000000000003', account_kind = 'CHECKING'
   WHERE id = '50000000-0000-7000-8000-000000000011';
$$, 'entry_workspace_id_account_id_account_kind_fkey');

-- T2: entry pointing to another tenant's account
SELECT pg_temp.expect_error($$
  UPDATE entry SET account_id = '20000000-0000-7000-8000-000000000009' WHERE id = '50000000-0000-7000-8000-000000000011';
$$, 'entry_workspace_id_account_id_account_kind_fkey');

-- O4: second opening on the same account
SELECT pg_temp.expect_error($$
  INSERT INTO operation (id, workspace_id, type, created_by, updated_by, updated_at) VALUES
    ('40000000-0000-7000-8000-0000000000a3', '10000000-0000-7000-8000-000000000001', 'OPENING', '00000000-0000-7000-8000-000000000001', '00000000-0000-7000-8000-000000000001', now());
  INSERT INTO entry VALUES ('50000000-0000-7000-8000-0000000000a3', '10000000-0000-7000-8000-000000000001', '40000000-0000-7000-8000-0000000000a3', 'OPENING', '20000000-0000-7000-8000-000000000001', 'CHECKING', '2026-09-01', 0);
$$, 'entry_one_opening_per_account_key');

-- Lines are only allowed on TRANSACTION
SELECT pg_temp.expect_error($$
  INSERT INTO line (id, workspace_id, operation_id, operation_type, category_id, amount, position) VALUES
    ('60000000-0000-7000-8000-0000000000a4', '10000000-0000-7000-8000-000000000001', '40000000-0000-7000-8000-000000000015', 'TRANSFER', '30000000-0000-7000-8000-000000000002', -1, 5);
$$, 'line_only_on_transaction_check');

-- P4: refund in a different category than its origin
SELECT pg_temp.expect_error($$
  UPDATE line SET category_id = '30000000-0000-7000-8000-000000000005' WHERE id = '60000000-0000-7000-8000-000000000015';
$$, 'line_workspace_id_refund_of_line_id_category_id_fkey');

-- R1: negative refund
SELECT pg_temp.expect_error($$
  UPDATE line SET amount = -45 WHERE id = '60000000-0000-7000-8000-000000000015';
$$, 'line_refund_check');

-- M2: more than 2 decimals in EUR
SELECT pg_temp.expect_error($$
  UPDATE entry SET amount = 2000.001 WHERE id = '50000000-0000-7000-8000-000000000010';
$$, 'entry_amount_scale_prototype_check');

-- A1: account kind cannot change once used (composite FK, no ON UPDATE action)
SELECT pg_temp.expect_error($$
  UPDATE account SET kind = 'SAVINGS' WHERE id = '20000000-0000-7000-8000-000000000001';
$$, 'entry_workspace_id_account_id_account_kind_fkey');

-- A1: account currency is immutable
SELECT pg_temp.expect_error($$
  UPDATE account SET currency = 'USD' WHERE id = '20000000-0000-7000-8000-000000000001';
$$, 'account_currency_immutable');

-- K1: duplicate category name, case-insensitive
SELECT pg_temp.expect_error($$
  INSERT INTO category (id, workspace_id, name, kind, updated_at) VALUES
    ('30000000-0000-7000-8000-0000000000a5', '10000000-0000-7000-8000-000000000001', 'HEALTH', 'EXPENSE', now());
$$, 'category_workspace_name_lower_key');

-- Opening cannot be voided
SELECT pg_temp.expect_error($$
  UPDATE operation SET voided_at = now(), voided_by = '00000000-0000-7000-8000-000000000001'
   WHERE id = '40000000-0000-7000-8000-000000000001';
$$, 'operation_opening_not_voided_check');

-- Audit log is append-only
INSERT INTO audit_event (id, workspace_id, actor_user_id, action, entity_type, entity_id) VALUES
  ('70000000-0000-7000-8000-000000000001', :W1, :U, 'operation.created', 'operation', '40000000-0000-7000-8000-000000000010');
SELECT pg_temp.expect_error($$
  UPDATE audit_event SET action = 'tampered' WHERE id = '70000000-0000-7000-8000-000000000001';
$$, 'audit_event_append_only');

\echo '--- accepted behaviours'

-- P4: recategorising the origin cascades to its refund
UPDATE line SET category_id = '30000000-0000-7000-8000-000000000005' WHERE id = '60000000-0000-7000-8000-000000000013';
SELECT CASE WHEN category_id = '30000000-0000-7000-8000-000000000005'
            THEN 'ok  refund category followed its origin'
            ELSE 'FAIL refund category not propagated' END AS result
  FROM line WHERE id = '60000000-0000-7000-8000-000000000015';
UPDATE line SET category_id = '30000000-0000-7000-8000-000000000003' WHERE id = '60000000-0000-7000-8000-000000000013';

-- Rebalancing a split inside one SQL transaction is accepted (checked at COMMIT only)
BEGIN;
UPDATE line SET amount = -70 WHERE id = '60000000-0000-7000-8000-000000000011';
UPDATE line SET amount = -23.84 WHERE id = '60000000-0000-7000-8000-000000000012';
COMMIT;
\echo 'ok  split rebalanced within one transaction'

-- Deleting an operation cascades to entries and lines without tripping the deferred check
BEGIN;
INSERT INTO operation (id, workspace_id, type, created_by, updated_by, updated_at) VALUES
  ('40000000-0000-7000-8000-0000000000b1', :W1, 'TRANSACTION', :U, :U, now());
INSERT INTO entry VALUES ('50000000-0000-7000-8000-0000000000b1', :W1, '40000000-0000-7000-8000-0000000000b1', 'TRANSACTION', :SG, 'CHECKING', '2026-10-11', -5);
INSERT INTO line (id, workspace_id, operation_id, operation_type, category_id, amount, position) VALUES
  ('60000000-0000-7000-8000-0000000000b1', :W1, '40000000-0000-7000-8000-0000000000b1', 'TRANSACTION', '30000000-0000-7000-8000-000000000005', -5, 0);
COMMIT;
DELETE FROM operation WHERE id = '40000000-0000-7000-8000-0000000000b1';
\echo 'ok  operation deleted with cascade'

\echo '--- balances and the C14 identity, per month'

WITH months AS (
  SELECT generate_series(date '2026-09-01', date '2026-11-01', interval '1 month')::date AS m
),
live_entry AS (
  SELECT e.*, date_trunc('month', e.date)::date AS m
    FROM entry e JOIN operation o ON o.id = e.operation_id
   WHERE o.voided_at IS NULL
),
cash_entry AS (
  SELECT * FROM live_entry WHERE account_kind IN ('CHECKING', 'SAVINGS')
),
transfer_side AS ( -- cash side of each transfer, with the kind of the other side
  SELECT c.m, c.amount, other.account_kind AS other_kind
    FROM cash_entry c
    JOIN live_entry other ON other.operation_id = c.operation_id AND other.id <> c.id
   WHERE c.operation_type = 'TRANSFER'
),
budget AS (
  SELECT date_trunc('month', e.date)::date AS m,
         sum(l.amount) FILTER (WHERE c.kind = 'INCOME')   AS income,
         -sum(l.amount) FILTER (WHERE c.kind = 'EXPENSE') AS net_expenses
    FROM line l
    JOIN operation o ON o.id = l.operation_id AND o.voided_at IS NULL
    JOIN entry e     ON e.operation_id = l.operation_id
    JOIN category c  ON c.id = l.category_id
   GROUP BY 1
),
figures AS (
  SELECT ms.m,
         coalesce(b.income, 0) AS income,
         coalesce(b.net_expenses, 0) AS net_expenses,
         coalesce((SELECT -sum(amount) FROM transfer_side t WHERE t.m = ms.m AND t.other_kind = 'INVESTMENT'), 0) AS invested,
         coalesce((SELECT sum(amount) FROM transfer_side t WHERE t.m = ms.m AND t.other_kind <> 'INVESTMENT'), 0) AS in_transit,
         coalesce((SELECT sum(amount) FROM cash_entry c WHERE c.m = ms.m AND c.operation_type = 'OPENING'), 0) AS openings,
         coalesce((SELECT sum(amount) FROM cash_entry c WHERE c.m = ms.m AND c.operation_type = 'ADJUSTMENT'), 0) AS adjustments,
         coalesce((SELECT sum(amount) FROM cash_entry c WHERE c.m = ms.m), 0) AS cash_delta
    FROM months ms LEFT JOIN budget b ON b.m = ms.m
)
SELECT m, income, net_expenses, income - net_expenses AS savings, invested, in_transit,
       openings, adjustments, cash_delta,
       (income - net_expenses) - invested + openings + adjustments + in_transit AS identity_rhs,
       CASE WHEN cash_delta = (income - net_expenses) - invested + openings + adjustments + in_transit
            THEN 'ok' ELSE 'FAIL' END AS identity
  FROM figures ORDER BY m;

SELECT a.name, sum(e.amount) AS balance_2026_10_31
  FROM account a
  JOIN entry e ON e.account_id = a.id
  JOIN operation o ON o.id = e.operation_id AND o.voided_at IS NULL
 WHERE e.date <= '2026-10-31' AND a.workspace_id = :W1
 GROUP BY a.name ORDER BY a.name;
