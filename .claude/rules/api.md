---
paths:
  - 'apps/api/**'
---

# API rules (ADR 0011, 0012, 0013)

- Write path: Zod validation (shape only) → controller maps to a command → idempotency check →
  unit of work (one SQL transaction that also sets the RLS settings) → load aggregates with the
  required row locks → domain rules → save → audit event → commit.
- Use cases depend on ports (repositories, `Clock`, `IdGenerator`), never on Prisma directly.
- Analytical reads (dashboard, balances) are SQL in the `reporting` module via `$queryRaw`
  tagged templates with a Zod schema per row. `$queryRawUnsafe` / `$executeRawUnsafe` are forbidden.
- HTTP: REST under `/api/v1/workspaces/:workspaceId/…`; `ETag` + `If-Match` (428 / 412);
  `Idempotency-Key` on every `POST`; errors as `application/problem+json` with a `code`; a resource
  of another workspace answers 404.
- Global HTTP settings live in `src/app.setup.ts` (`configureApp`), shared by `main.ts` and tests.
- Configuration comes from environment variables validated at startup; document each new variable
  in `.env.example`.
