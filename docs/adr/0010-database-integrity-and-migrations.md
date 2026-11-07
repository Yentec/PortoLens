# 0010. Database integrity and migrations

- Status: Accepted
- Date: 2026-11-07

## Decision

### Where invariants live

- **Domain** (the `Operation` aggregate): rules internal to one operation.
- **Use case** (inside one SQL transaction, with row locks): rules across aggregates (archived
  account, tracking start date, refund origin, category kind change).
- **Database**, as a safety net wherever cheaply expressible:
  - deferred constraint triggers check each operation's structure at `COMMIT` (balance of lines,
    transfer shape, opening/adjustment shape);
  - `CHECK` constraints (non-zero amounts, EUR scale, lines only on transactions, positive refunds);
  - partial and expression unique indexes (one opening per account, case-insensitive names);
  - immutable attributes copied to child rows (`operation_type`, `account_kind`) and pinned by
    composite foreign keys, so `CHECK` constraints can use them;
  - refund foreign key including `category_id` with `ON UPDATE CASCADE`.
- Foreign keys declare `onUpdate: NoAction` explicitly (Prisma defaults to `CASCADE`, which would
  defeat immutability) and `onDelete: NoAction` rather than `Restrict` (checked at statement end,
  so a whole-workspace purge works).
- `audit_event` is append-only (update trigger + role grants).

### Migrations

- Workflow: edit `schema.prisma` → `prisma migrate dev --create-only` → review the generated SQL →
  add hand-written SQL (constraints, indexes, triggers, RLS policies) → apply → run tests.
- **`prisma db push` is forbidden**: it would ignore hand-written SQL. Prisma ignores these objects
  when diffing (verified), so both coexist.
- Merged migrations are immutable; migrations are forward-only (incidents are handled by
  point-in-time recovery); each migration stays compatible with the previous application version;
  breaking changes follow expand → migrate → contract; large-table constraints use `NOT VALID`
  then `VALIDATE CONSTRAINT`.
- Roles are created by an infrastructure script, not by migrations. Migrations set
  `ALTER DEFAULT PRIVILEGES` for `app_runtime`.
- CI fails on schema drift (`prisma migrate diff --exit-code`).

## Consequences

- A violation of a database invariant is a bug (the domain should have caught it): it maps to HTTP
  500 and is logged.
