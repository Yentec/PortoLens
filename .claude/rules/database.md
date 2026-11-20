---
paths:
  - 'apps/api/prisma/**'
  - '**/*.sql'
---

# Database and migration rules (ADR 0009, 0010)

- Workflow: edit `schema.prisma` → `prisma migrate dev --create-only` → review the generated SQL →
  append hand-written SQL (CHECK constraints, partial/expression indexes, deferred triggers, RLS
  policies, grants) → apply → run the tests. **Never `prisma db push`.**
- Merged migrations are immutable and forward-only; each migration stays compatible with the
  previous application version (expand → migrate → contract for breaking changes).
- Every table with `workspace_id`: composite foreign keys `(workspace_id, …)`, RLS enabled **and**
  forced with a `tenant_isolation` policy on `current_setting('app.workspace_id', true)`.
- Set `onUpdate` and `onDelete` explicitly on every relation (`NoAction` by default; Prisma would
  otherwise use `CASCADE` on update).
- Money columns `Decimal @db.Decimal(19, 4)`; business dates `@db.Date`; instants
  `@db.Timestamptz(3)`; ids `@db.Uuid` without database default.
- Start from the validated draft in `docs/design/data-model-draft/`.
