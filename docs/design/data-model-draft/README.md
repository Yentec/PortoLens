# Data model draft

Validated during the design phase (step 4) on PostgreSQL 16 with Prisma 7.10: generated migration +
hand-written constraints, then `ledger_tests.sql` (19 rejections, accepted behaviours and the C14
identity per month). It is **not applied** yet: lot 2 turns it into real migrations.

| File                     | Content                                                                       |
| ------------------------ | ----------------------------------------------------------------------------- |
| `schema.prisma`          | Prisma schema (composite tenant foreign keys, explicit `onUpdate`/`onDelete`) |
| `ledger_constraints.sql` | Hand-written migration: CHECKs, partial/expression indexes, deferred triggers |
| `ledger_tests.sql`       | psql integration script used to validate the constraints                      |

Known gaps to address in lot 2: RLS policies and database roles (ADR 0009), the `tracking_start_date`
rules enforced by use cases, Prisma 7 configuration (`prisma.config.ts`, driver adapter).
