# 0016. Deferred capabilities

- Status: Accepted
- Date: 2026-11-07

## Decision

These capabilities are out of the prototype; their direction is fixed so the current design does
not block them.

- **Bank data**: file import first (OFX, then bank CSV such as BoursoBank). Aggregators (PSD2
  account information) are on hold: cost and contractual dependency are too high for the current
  scope. Imported data will land in an immutable raw `BankTransaction` layer, deduplicated, linked
  one-to-one to an `Entry`; a linked entry's amount and date are locked (the bank is authoritative
  on facts, the user on classification). Pending card transactions are not posted.
- **Recurring operations**: generated as `PLANNED` operations, visible up to one month ahead.
- **Budgets, goals**: new tables; goals of the workbook are target amounts by year bracket.
- **Specialised modules** (investments, real estate, vehicles, collections, valuables, custom
  assets): the core keeps the shared invariant (the ledger); each module adds a one-to-one
  extension table and its own rules, and references transactions rather than re-entering them.
- **Households**: additional members of a workspace and a `RoleGuard`.
- **Professional accounts**: a product decision with an explicit rule, later.
- **Billing**: the last major feature; it feeds per-workspace feature activation.
- **Hosting**: EU-headquartered provider with managed PostgreSQL. Shortlist: Clever Cloud, Scaleway
  (fallback UpCloud, IONOS). The choice requires a hands-on check: creating the three roles with
  RLS enforced, and a real point-in-time restore.
