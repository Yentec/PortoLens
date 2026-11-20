-- Ledger constraints that Prisma cannot express in schema.prisma.
-- Applied as a hand-written migration right after the generated one.

-- ─── Expression and partial unique indexes ─────────────────────────────────────

CREATE UNIQUE INDEX user_email_lower_key ON "user" (lower(email));
CREATE UNIQUE INDEX account_workspace_name_lower_key ON account (workspace_id, lower(name));
CREATE UNIQUE INDEX category_workspace_name_lower_key ON category (workspace_id, lower(name));

-- O4: one OPENING per account.
CREATE UNIQUE INDEX entry_one_opening_per_account_key ON entry (account_id)
  WHERE operation_type = 'OPENING';

-- ─── CHECK constraints ─────────────────────────────────────────────────────────

ALTER TABLE workspace
  ADD CONSTRAINT workspace_base_currency_prototype_check CHECK (base_currency = 'EUR');

ALTER TABLE account
  -- M4 (prototype): EUR only. Lifting it = dropping this constraint + per-currency scale check.
  ADD CONSTRAINT account_currency_prototype_check CHECK (currency = 'EUR'),
  ADD CONSTRAINT account_name_not_blank_check CHECK (btrim(name) <> ''),
  ADD CONSTRAINT account_version_check CHECK (version >= 1);

ALTER TABLE category
  ADD CONSTRAINT category_name_not_blank_check CHECK (btrim(name) <> ''),
  ADD CONSTRAINT category_version_check CHECK (version >= 1);

ALTER TABLE operation
  ADD CONSTRAINT operation_is_fixed_check CHECK (NOT is_fixed OR type = 'TRANSACTION'),
  ADD CONSTRAINT operation_checkpoint_check CHECK (checkpoint_id IS NULL OR type = 'ADJUSTMENT'),
  ADD CONSTRAINT operation_voided_check CHECK ((voided_at IS NULL) = (voided_by IS NULL)),
  ADD CONSTRAINT operation_opening_not_voided_check CHECK (voided_at IS NULL OR type <> 'OPENING'),
  ADD CONSTRAINT operation_version_check CHECK (version >= 1);

ALTER TABLE entry
  -- M1: non-zero except OPENING.
  ADD CONSTRAINT entry_amount_non_zero_check CHECK (amount <> 0 OR operation_type = 'OPENING'),
  -- M2 (prototype, EUR): 2 decimals.
  ADD CONSTRAINT entry_amount_scale_prototype_check CHECK (amount = round(amount, 2)),
  -- A3: no TRANSACTION on an investment account.
  ADD CONSTRAINT entry_transaction_on_cash_account_check
    CHECK (operation_type <> 'TRANSACTION' OR account_kind <> 'INVESTMENT');

ALTER TABLE line
  ADD CONSTRAINT line_only_on_transaction_check CHECK (operation_type = 'TRANSACTION'),
  ADD CONSTRAINT line_amount_non_zero_check CHECK (amount <> 0),
  ADD CONSTRAINT line_amount_scale_prototype_check CHECK (amount = round(amount, 2)),
  -- R1/R3 (structural part): a refund is positive and never refunds itself.
  ADD CONSTRAINT line_refund_check
    CHECK (refund_of_line_id IS NULL OR (amount > 0 AND refund_of_line_id <> id)),
  ADD CONSTRAINT line_position_check CHECK (position >= 0);

ALTER TABLE checkpoint
  ADD CONSTRAINT checkpoint_balance_scale_prototype_check
    CHECK (declared_balance = round(declared_balance, 2));

-- ─── A1: account currency is immutable ─────────────────────────────────────────
-- (kind is already immutable once used: the composite FK from entry has no ON UPDATE action.)

CREATE FUNCTION account_guard_immutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.currency IS DISTINCT FROM OLD.currency THEN
    RAISE EXCEPTION 'account currency is immutable'
      USING ERRCODE = '23514', CONSTRAINT = 'account_currency_immutable';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER account_guard_immutable
  BEFORE UPDATE OF currency ON account
  FOR EACH ROW EXECUTE FUNCTION account_guard_immutable();

-- ─── O2/O3/O4/O5: operation structure, checked at COMMIT ───────────────────────

CREATE FUNCTION ledger_assert_operation(p_operation_id uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_type        operation_type;
  v_entries     int;
  v_entry_sum   numeric;
  v_currencies  int;
  v_debit_date  date;
  v_credit_date date;
  v_lines       int;
  v_line_sum    numeric;
  v_problem     text;
BEGIN
  SELECT type INTO v_type FROM operation WHERE id = p_operation_id;
  IF NOT FOUND THEN
    RETURN; -- operation deleted in this transaction (children cascade)
  END IF;

  SELECT count(*),
         coalesce(sum(e.amount), 0),
         count(DISTINCT a.currency),
         max(e.date) FILTER (WHERE e.amount < 0),
         max(e.date) FILTER (WHERE e.amount > 0)
    INTO v_entries, v_entry_sum, v_currencies, v_debit_date, v_credit_date
    FROM entry e
    JOIN account a ON a.id = e.account_id
   WHERE e.operation_id = p_operation_id;

  SELECT count(*), coalesce(sum(amount), 0)
    INTO v_lines, v_line_sum
    FROM line
   WHERE operation_id = p_operation_id;

  CASE v_type
    WHEN 'TRANSACTION' THEN
      IF v_entries <> 1 THEN
        v_problem := format('expected 1 entry, found %s', v_entries);
      ELSIF v_lines < 1 THEN
        v_problem := 'expected at least 1 line';
      ELSIF v_line_sum <> v_entry_sum THEN
        v_problem := format('lines sum %s <> entry amount %s', v_line_sum, v_entry_sum);
      END IF;
    WHEN 'TRANSFER' THEN
      IF v_entries <> 2 THEN
        v_problem := format('expected 2 entries, found %s', v_entries);
      ELSIF v_lines <> 0 THEN
        v_problem := 'a transfer has no lines';
      ELSIF v_entry_sum <> 0 THEN
        v_problem := format('entries sum %s <> 0', v_entry_sum);
      ELSIF v_currencies <> 1 THEN
        v_problem := 'transfer across currencies';
      ELSIF v_credit_date < v_debit_date THEN
        v_problem := format('credit date %s before debit date %s', v_credit_date, v_debit_date);
      END IF;
    ELSE -- OPENING, ADJUSTMENT
      IF v_entries <> 1 THEN
        v_problem := format('expected 1 entry, found %s', v_entries);
      ELSIF v_lines <> 0 THEN
        v_problem := format('%s has no lines', v_type);
      END IF;
  END CASE;

  IF v_problem IS NOT NULL THEN
    RAISE EXCEPTION 'invalid % operation %: %', v_type, p_operation_id, v_problem
      USING ERRCODE = '23514', CONSTRAINT = 'operation_structure';
  END IF;
END $$;

CREATE FUNCTION ledger_check_operation() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_TABLE_NAME = 'operation' THEN
    PERFORM ledger_assert_operation(NEW.id);
  ELSE
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
      PERFORM ledger_assert_operation(NEW.operation_id);
    END IF;
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
      PERFORM ledger_assert_operation(OLD.operation_id);
    END IF;
  END IF;
  RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER operation_structure_on_operation
  AFTER INSERT OR UPDATE ON operation
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION ledger_check_operation();

CREATE CONSTRAINT TRIGGER operation_structure_on_entry
  AFTER INSERT OR UPDATE OR DELETE ON entry
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION ledger_check_operation();

CREATE CONSTRAINT TRIGGER operation_structure_on_line
  AFTER INSERT OR UPDATE OR DELETE ON line
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION ledger_check_operation();

-- ─── Audit log is append-only ──────────────────────────────────────────────────
-- DELETE stays possible for the GDPR purge (workspace cascade); it will be restricted by
-- database roles in step 7 (application role: INSERT/SELECT only).

CREATE FUNCTION audit_event_append_only() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_event is append-only'
    USING ERRCODE = '42501', CONSTRAINT = 'audit_event_append_only';
END $$;

CREATE TRIGGER audit_event_append_only
  BEFORE UPDATE ON audit_event
  FOR EACH ROW EXECUTE FUNCTION audit_event_append_only();
