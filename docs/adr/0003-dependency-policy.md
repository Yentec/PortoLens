# 0003. Dependency policy

- Status: Accepted
- Date: 2026-11-07

## Decision

A library is added when it brings a **real gain** (time saved, tricky correctness handled, security
expertise) **and** is actively maintained. Code is written in-house when the gain is small
(roughly under 50 lines) or when the integration would have to be wrapped anyway.

| Need                      | Choice                                    | Reason                                                    |
| ------------------------- | ----------------------------------------- | --------------------------------------------------------- |
| Unit of work              | In-house (`AsyncLocalStorage`)            | Must run RLS `set_config` at each transaction start       |
| Validation pipe           | In-house, `nestjs-zod`-compatible API     | `nestjs-zod` does not support NestJS 12 yet               |
| Problem Details filter    | In-house                                  | A few lines of mapping                                    |
| Better Auth ↔ NestJS glue | In-house                                  | Community package has a single maintainer; glue is small  |
| UUIDv7                    | `uuid`                                    | Monotonic ordering within one millisecond is subtle       |
| HTTP security headers     | `helmet`                                  | Header list evolves with browsers                         |
| Rate limiting             | `@nestjs/throttler`                       | Maintained by the NestJS team                             |
| Authentication            | Better Auth                               | Sessions, verification, reset, TOTP, passkeys             |
| Frontend server state     | TanStack Query                            | Cache and invalidation across balances, lists and reports |
| Exact decimals / schemas  | decimal.js / Zod                          | Core needs                                                |
| Tests                     | Vitest, fast-check, supertest, Playwright | See 0015                                                  |

Rejected: `nestjs-cls` (RLS wrapper needed anyway), `eslint-config-prettier` (no conflicting rules),
Testcontainers (a CI service container is enough).

## Consequences

- When `nestjs-zod` supports NestJS 12, migrating means replacing two imports.
- Each new dependency is justified against this policy in its pull request.
