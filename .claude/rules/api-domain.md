---
paths:
  - 'apps/api/src/modules/*/domain/**'
---

# Domain layer rules (ADR 0004–0008, ADR 0011)

- Pure TypeScript: no NestJS decorators, no Prisma, no HTTP, no `@portolens/contracts`, no Node.js
  built-ins. Allowed: the same module's domain, `@portolens/primitives`, decimal.js.
- The `Operation` aggregate owns its entries and lines and enforces, before any persistence:
  - `TRANSACTION`: one entry on a cash account, at least one line, sum of lines = entry amount;
  - `TRANSFER`: two entries, distinct accounts, same currency, opposite non-zero amounts,
    credit date ≥ debit date, no lines;
  - `OPENING` / `ADJUSTMENT`: one entry, no lines; the type never changes.
- Refund lines are positive lines in an `EXPENSE` category; a linked refund has the origin's
  category; refund status (`NONE`, `PARTIAL`, `FULL`, `EXCEEDED`) is computed, never stored.
- Violations throw typed domain errors carrying a stable `code` (e.g. `LEDGER_LINES_UNBALANCED`).
- Every rule gets a unit test named after its identifier (`O2 …`, `R4 …`); prefer fast-check
  property tests for arithmetic invariants.
