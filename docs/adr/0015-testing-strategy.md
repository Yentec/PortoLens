# 0015. Testing strategy

- Status: Accepted
- Date: 2026-11-07

## Decision

| Level              | Scope                                                          | Tools              |
| ------------------ | -------------------------------------------------------------- | ------------------ |
| Unit               | `Money`, `CalendarDate`, domain aggregates, refund status      | Vitest             |
| Property           | Line balance; C14 identity on generated ledgers                | fast-check         |
| Integration (core) | Use cases, repositories, SQL read models, triggers, locks, RLS | Vitest, PostgreSQL |
| API                | Contracts, status codes, `If-Match`, `Idempotency-Key`, guards | Vitest, supertest  |
| End-to-end         | A few critical journeys                                        | Playwright         |

- **Isolation**: one database per test file, cloned from a migrated template database; tests
  perform real `COMMIT`s. Rollback-based isolation is forbidden: deferred triggers never run on
  `ROLLBACK` (verified).
- Tests connect as `app_runtime`; only fixture setup uses the owner role.
- Targeted tests: RLS isolation on every workspace table, schema lint queries on `pg_catalog` (RLS
  forced, composite tenant foreign keys, audit grants), concurrency (void vs. refund link), daylight
  saving time, API responses validated against `contracts`.
- Reference dataset: the Excel workbook imported and **anonymised** in the repository (labels and
  names replaced); the original file never enters the repository. Expected monthly figures are
  frozen as regression values.
- No global coverage target: every invariant and edge case identifier has at least one test named
  after it.
- PostgreSQL runs in `docker compose` locally and as a service container in CI; no Testcontainers.

### CI pipeline

1. install, lint, typecheck, dependency-cruiser
2. unit and property tests
3. create roles, `migrate deploy`, drift check, schema lint tests
4. integration and API tests
5. build
6. end-to-end tests (on `main` or on demand)
