# Portolens — instructions for Claude Code

Multi-user SaaS for personal finance and wealth management, built as a modular monolith.
The prototype reproduces the financial core of a personal Excel workbook (accounts, transactions,
transfers, refunds, checkpoints, dashboard), then grows optional modules.

- **Architecture decisions**: `docs/adr/` (index in `docs/adr/README.md`). Read the ADRs of the area
  you touch before changing it. Never contradict an accepted ADR: propose a new ADR instead (ADR 0000).
- **Roadmap and current status**: `docs/roadmap.md`. Update it at the end of each lot.
- **Data model draft** (validated design, not yet applied): `docs/design/data-model-draft/`.

## Working with the developer

The developer is a fullstack TypeScript developer who wants to understand every decision, not only
receive code. These rules apply to every task.

- **Talk to the developer in French.** Everything written in the repository is in English (code,
  comments, tests, commit messages, docs). Only UI text exists in both languages, through i18next.
- **One step at a time.** Before coding, explain the plan, the options considered and the trade-offs,
  and recommend one. Stop at the end of each step and wait for validation before the next one.
- **Git**: never commit, push, merge, rebase or delete a branch without explicit approval.
  - Work outside `main`. At the start of a lot, give the branch command:
    `git switch -c feat/lot-NN-<topic>` (one branch per lot; `fix/…`, `docs/…`, `chore/…` otherwise).
  - Split the work into successive commits. For each commit give: the files changed, the commit
    message in Conventional Commits format `<type>(<scope>): <subject>` with a bullet-list body, and
    the verification steps with their expected results.
  - Before each commit, remind the developer to bump the version of every touched `package.json`:
    `npm version x.y.z --no-git-tag-version` (add `-w @portolens/<name>` for a workspace).
    Patch bump per commit during a lot; at the end of a lot, every package touched during the lot
    moves to the next minor (`0.N.0`).
- **Definition of done** for a step: `npm run verify` passes, every new rule has a test, error codes
  are translated (en + fr), ADRs and `docs/roadmap.md` are up to date.
- **Dependencies** (ADR 0003): add one only for a real gain and if actively maintained. Check the
  latest stable version first, pin it exactly (`save-exact`), and say why it is needed. Keep one
  version of a shared tool across workspaces (vite, vitest, typescript).

## Commands (run from the repository root)

| Command                                                  | Purpose                                                        |
| -------------------------------------------------------- | -------------------------------------------------------------- |
| `npm run verify`                                         | Whole CI locally: format, lint, lint:deps, types, tests, build |
| `npm test` / `npm test -w @portolens/api`                | All tests / one workspace                                      |
| `npm run typecheck`, `npm run lint`, `npm run lint:deps` | Individual checks                                              |
| `npm run format`                                         | Prettier (never format by hand)                                |
| `npm run dev:api` / `npm run dev:web`                    | API on :3000, web on :5173 (Vite proxies `/api`)               |
| `npm run db:up` / `db:down` / `db:psql` / `db:logs`      | Local PostgreSQL 18 (docker compose, reads `.env`)             |

## Repository layout

```
apps/api            @portolens/api — NestJS 12 (ESM), Vitest + supertest
apps/web            @portolens/web — React 19 + Vite 8, i18next, TanStack Query, Vitest + jsdom
packages/           shared libraries (lot 1: primitives; later: contracts)
docs/adr            architecture decision records
.github/workflows   CI (single job mirroring `npm run verify`)
compose.yaml        local PostgreSQL 18.7
```

Toolchain: Node 26 (`.nvmrc`), npm 11 workspaces, TypeScript 6.0 (not 7: typescript-eslint
supports `< 6.1`), ESLint 10 type-aware, Prettier, dependency-cruiser, Dependabot.

## Conventions

- **Modules**: `apps/api/src/modules/<module>/{domain,application,infrastructure,http}`. Boundaries
  are enforced by `.dependency-cruiser.js`: fix the code, never loosen a rule without an ADR.
- **Imports**: API relative imports end with `.js` (NodeNext); web imports have no extension.
- **NestJS DI**: never `import type` a class that is injected (decorator metadata would be lost).
- **Money**: never floating point. Amounts are signed from the account's point of view, stored as
  `NUMERIC(19,4)`, `Money` value object (decimal.js) in code, decimal strings in the API.
- **Dates**: business dates are calendar dates (`YYYY-MM-DD`, `CalendarDate`), never a local `Date`;
  instants are UTC `timestamptz`. "Today" is computed in the workspace time zone (ADR 0005).
- **IDs**: UUIDv7 generated by the application.
- **Errors**: the backend returns stable `code`s (Problem Details, RFC 9457), never display text;
  the frontend translates them.
- **Tenancy**: every business row has `workspace_id`; repositories read it from the request context
  only, never from the request (ADR 0009).
- **Tests**: Vitest with explicit imports. Name tests after the invariant or edge case they cover
  (`O2`, `R4`, `C14`… from ADRs 0004–0010). No logging with `console` (use the NestJS `Logger`).
- **Security**: no secrets in the repository (`.env` is ignored; document variables in
  `.env.example`). **Personal financial data (the Excel workbook, bank exports) never enters the
  repository**; only anonymised fixtures under a `fixtures/` folder.

## Pitfalls already met (do not rediscover them)

- A brand-new workspace must be registered with a plain `npm install` before
  `npm install -w <workspace> <packages>` records dependencies.
- Vitest (Vite 8 / Oxc) emits decorator metadata only because `apps/api/vitest.config.ts` sets
  `oxc.decorator`; `apps/api/test/toolchain.spec.ts` guards it.
- `fetch` does not reject on HTTP errors: always check `response.ok`.
- dependency-cruiser stops on a missing folder: add `packages` to `lint:deps` when it exists.
- Prisma defaults foreign keys to `ON UPDATE CASCADE`: always set `onUpdate`/`onDelete` explicitly.
- Deferred constraint triggers never run on `ROLLBACK`: integration tests commit for real, one
  database per test file, connected as `app_runtime` (a superuser bypasses RLS). See ADR 0015.
