# 0002. Repository layout and toolchain

- Status: Accepted
- Date: 2026-11-07

## Decision

### Layout (npm workspaces)

```
apps/api            NestJS: domain, use cases, persistence, HTTP
apps/web            React + Vite
packages/primitives Money, CalendarDate, Currency (pure TypeScript, decimal.js only)
packages/contracts  HTTP request/response schemas (Zod) and inferred types
docs/adr            architecture decision records
```

- The domain lives in `apps/api` only; it is never shared with the frontend (the server is
  authoritative, the frontend validates for UX only).
- `contracts` depends on `primitives`; the domain depends on `primitives`; the domain never depends
  on `contracts`, Prisma or HTTP.
- No package is created without a real responsibility.

### Toolchain

- Node.js 26 (active LTS), npm 11, enforced by `engines` + `engine-strict`.
- `save-exact`: dependency versions are pinned; upgrades are deliberate.
- TypeScript 6.0.x. TypeScript 7 is not adopted yet: typescript-eslint supports `< 6.1`.
- Shared strict `tsconfig.base.json` (`strict`, `noUncheckedIndexedAccess`, `isolatedModules`…);
  each app sets its own module system. `exactOptionalPropertyTypes` is off (conflicts with
  generated Prisma and Zod types).
- Prettier formats; ESLint (flat config, typescript-eslint `recommendedTypeChecked`) checks quality
  only. No stylistic ESLint rules, therefore no `eslint-config-prettier`.
- `consistent-type-imports` is not enabled: `import type` would erase classes that NestJS needs at
  runtime for dependency injection.
- Module boundaries are enforced in CI by dependency-cruiser (0011).
- Vitest for every package; Playwright for end-to-end tests (0015).

## Consequences

- Every TypeScript file must belong to a `tsconfig.json` (required by ESLint `projectService`).
- Moving to TypeScript 7 is a future ADR once the lint ecosystem supports it.
