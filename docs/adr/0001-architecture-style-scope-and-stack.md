# 0001. Architecture style, prototype scope and stack

- Status: Accepted
- Date: 2026-11-07

## Context

The product is a multi-user SaaS for personal finance and wealth management. It starts from a
personal Excel workbook (`Account book 2026`) and will later grow optional modules (vehicles, real
estate, collections, valuables, investments, custom assets). Financial operations require strong
transactional consistency.

## Decision

- **Modular monolith**: one deployable backend organised by business modules. No microservices.
- **Backend**: Node.js, TypeScript, NestJS 12 with its default Express adapter.
- **Frontend**: React + Vite. The app is private and interactive; SEO and server rendering are not
  needed, so Next.js is not used.
- **Database**: PostgreSQL with Prisma ORM 7.x (stable line; 8.x is not adopted while in release
  candidate).
- **Multi-user from day one**. Billing and subscriptions are the last major feature, but data is
  owned by a workspace that can later carry a plan (see 0009).

### Prototype scope

In scope: authentication and workspace, accounts (cash accounts and investment accounts as net
contributions), categories, transactions with splits, transfers, refunds, balance checkpoints and a
dashboard computed from real data.

Out of scope: recurring operations, budgets, goals, bank import, multi-currency, asset valuation,
specialised modules, household sharing UI, professional accounts, billing (see 0016).

## Alternatives considered

- Microservices: no need justifies their operational cost; they break single-transaction
  consistency of financial operations.
- Next.js: its server-side features add conceptual cost without benefit for a private dashboard.
- NestJS with Fastify: no identified need; Express is the default adapter. Adapters are never
  stacked.

## Consequences

- Modules must keep explicit boundaries (0011) so that one could be extracted later if ever needed.
- All financial writes can run in a single PostgreSQL transaction.
