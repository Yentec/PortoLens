# Roadmap

Implementation order of the prototype (design phase: ADRs 0000–0016). Each lot ends with something
that works, is tested and passes CI. Sizes are relative (S < M < L).

| Lot | Content                                                                                                                          | Size | Status                |
| --- | -------------------------------------------------------------------------------------------------------------------------------- | ---- | --------------------- |
| 0   | Foundations: monorepo, TypeScript, Prettier, ESLint, ADRs, API and web skeletons, tests, PostgreSQL, dependency-cruiser, CI      | M    | Done (packages 0.2.0) |
| 1   | `packages/primitives`: `Money`, `CalendarDate`, `today(timeZone)`, UUIDv7 wrapper; unit and property tests; `contracts` skeleton | S    | Next                  |
| 2   | Data foundation: Prisma schema and migrations (from the draft), RLS, roles script, test databases per file, schema lint tests    | M    | To do                 |
| 3   | Platform: request context, unit of work, Problem Details, `ZodValidationPipe`, idempotency, audit, helmet, throttler             | M    | To do                 |
| 4   | Identity and workspace: Better Auth, sessions, guards, workspace creation with default categories                                | L    | To do                 |
| 5   | Accounts and categories                                                                                                          | M    | To do                 |
| 6   | Transactions: splits, fixed charges, voiding, operation list                                                                     | L    | To do                 |
| 7   | Transfers                                                                                                                        | S    | To do                 |
| 8   | Refunds                                                                                                                          | M    | To do                 |
| 9   | Dashboard (SQL read models, C14 property test, anonymised workbook fixture)                                                      | L    | To do                 |
| 10  | Checkpoints and adjustments                                                                                                      | S    | To do                 |
| 11  | Security and GDPR: TOTP, sessions management, security events, export and erasure, CSP                                           | M    | To do                 |
| 12  | Release: hosting check, deployment, restore drill, monitoring, end-to-end suite                                                  | M    | To do                 |

Milestones: M1 after lot 9 (replaces the workbook's core locally), M2 after lot 10 (reconciled with
bank statements), M3 after lot 12 (ready for first users).

## Lot 0 outcome

- Versions: root, `@portolens/api` and `@portolens/web` at 0.2.0.
- SWC was not needed: Vite 8's Oxc emits decorator metadata when configured (ADR 0003 policy).
