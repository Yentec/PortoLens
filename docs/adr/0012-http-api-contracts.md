# 0012. HTTP API contracts

- Status: Accepted
- Date: 2026-11-07

## Decision

- **REST JSON**, versioned under `/api/v1`, with Zod schemas shared in `packages/contracts`. A custom
  `ZodValidationPipe` mirrors the `nestjs-zod` API (`createZodDto`) for an easy future migration.
- **Workspace in the path**: `/api/v1/workspaces/:workspaceId/...`. The guard checks membership and
  sets the context; repositories still read the context only.
- **Typed writes, unified reads**: `POST/PUT /transactions`, `POST/PUT /transfers`;
  `GET /operations`, `GET /operations/:id`, `POST /operations/:id/void`. Openings are managed
  through accounts (`PUT /accounts/:id/opening`), adjustments through checkpoints
  (`POST /checkpoints/:id/adjustment`). State changes are explicit commands (`/archive`, `/void`).
- **Transaction payload**: full `PUT`; `amount` (the bank movement) is sent and checked against the
  sum of lines; lines carry stable ids (with id = update, without id = create, missing = delete;
  deleting a refunded line is rejected); a refund line has `refundOfLineId` and no `categoryId`.
- **Transfer payload**: positive `amount`, `fromAccountId`, `toAccountId`, `debitDate`, `creditDate`.
- **Concurrency**: responses carry `ETag` and `version`; mutations require `If-Match` (428 when
  missing, 412 when stale).
- **Idempotency**: every `POST` requires `Idempotency-Key` (one per user intent); same key and
  payload replays the stored response.
- **Operation list**: keyset pagination on (`date` desc, `id` desc) with an opaque cursor; filters
  (account, category, type, period, text, voided); `balanceAfter` when filtered on one account.
- **Formats**: amounts as strings (`{amount, currency}` in responses), `YYYY-MM-DD` dates,
  `YYYY-MM` months, UTC ISO instants, UUID strings, `camelCase` properties, `UPPER_SNAKE` enums,
  nullable fields always present, errors as `application/problem+json`.
- **Frontend data layer**: TanStack Query over a typed `fetch` client that handles
  `Idempotency-Key`, `If-Match` and Problem Details.

## Alternatives considered

- tRPC: bypasses NestJS guards and filters and couples both apps tightly.
- GraphQL: oversized for a single client we control.
