# 0011. Backend architecture

- Status: Accepted
- Date: 2026-11-07

## Decision

### Modules (one per business area, not per table)

| Module      | Responsibility                                                                | Writes                           |
| ----------- | ----------------------------------------------------------------------------- | -------------------------------- |
| `platform`  | Prisma, unit of work, request context, clock, ids, audit, idempotency, errors | `audit_event`, `idempotency_key` |
| `identity`  | Users and authentication                                                      | auth tables                      |
| `workspace` | Tenant, membership, settings, default categories                              | `workspace`, `membership`        |
| `ledger`    | Accounts, categories, operations, checkpoints (4 aggregates)                  | ledger tables                    |
| `reporting` | Dashboard, balances, refund status — read-only SQL                            | nothing                          |

Only `ledger` writes ledger tables; `reporting` reads them. `ledger` keeps its own balance queries
and never depends on `reporting`.

### Layers inside `ledger`

`domain` (no NestJS, no Prisma) → `application` (use cases, ports) → `infrastructure` (Prisma
repositories, mappers, database error translation) → `http` (controllers, contracts mapping).
Modules call each other only through exported application services. Rules are enforced by
dependency-cruiser in CI. Ports exist only for repositories, `Clock` and `IdGenerator`.

### Write path

Zod validation (shape) → controller maps to a command → idempotency check → unit of work (one SQL
transaction with RLS settings) → load aggregates with locks → domain rules → save → audit → commit.

- Optimistic concurrency with a `version` column on operations.
- Row locks for cross-aggregate rules: `FOR SHARE` on the account while writing an operation,
  `FOR UPDATE` on the account while archiving, `FOR SHARE` on the origin operation while linking a
  refund.
- Validation: Zod checks shape and format; business rules live only in the domain.

### Read models

- Analytical reads use SQL through `$queryRaw` tagged templates (bound parameters) with a Zod schema
  per result row. `$queryRawUnsafe` is forbidden (ESLint). Prisma TypedSQL will be considered when
  it leaves preview.

### Errors

| Origin                                | HTTP      | Body                                   |
| ------------------------------------- | --------- | -------------------------------------- |
| Business rule                         | 422       | Problem Details (RFC 9457) with `code` |
| Unknown or other-tenant resource      | 404       |                                        |
| Missing `If-Match` / stale version    | 428 / 412 | `CONCURRENT_MODIFICATION`              |
| Expected unique violation             | 409       | specific code                          |
| Idempotency key reused, other payload | 422       | `IDEMPOTENCY_KEY_REUSED`               |
| Database invariant violation          | 500       | logged as a bug                        |

The backend never returns human-readable text for display; the frontend translates `code`.

## Consequences

- Use cases are tested mainly against a real PostgreSQL (0015).
