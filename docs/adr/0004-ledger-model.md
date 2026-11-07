# 0004. Ledger model

- Status: Accepted
- Date: 2026-11-07

## Context

In the Excel workbook, monthly sheets classify income and expenses but are not linked to accounts,
transfers are not recorded, and balances are typed by hand each month. Budget and balances can
silently disagree.

## Decision

- **The ledger is the source of truth**: an account balance is computed, never typed.
  `balance(account, d) = Σ amount of entries dated ≤ d whose operation is not voided`.
- **Operation** is the business event and aggregate root; it produces **entries** (effect on one
  account) and, for transactions, **lines** (budget allocation).

| Type          | Entries | Lines | Rules                                                       |
| ------------- | ------- | ----- | ----------------------------------------------------------- |
| `TRANSACTION` | 1       | ≥ 1   | Σ lines = entry amount                                      |
| `TRANSFER`    | 2       | 0     | Distinct accounts, same currency, opposite non-zero amounts |
| `OPENING`     | 1       | 0     | One per account, at its tracking start date, may be zero    |
| `ADJUSTMENT`  | 1       | 0     | Explicitly created to absorb a checkpoint discrepancy       |

- **Tracking start date**: the `OPENING` is the balance at the date the account starts being
  tracked in the app, not the bank's real opening date. Adding older history moves the opening date
  back and recomputes the opening amount, keeping the most recent known balance fixed.
- **Account kinds**: `CHECKING`, `SAVINGS` (cash) and `INVESTMENT` (see 0007). Kind and currency
  are immutable.
- **Checkpoint**: a declared balance at a date. The discrepancy (declared − computed) is computed on
  read, never stored. It is never corrected automatically: the user creates an `ADJUSTMENT`.
- Lines act as counterpart entries and categories as nominal accounts: the model can evolve to full
  double-entry bookkeeping without rewriting data.

## Alternatives considered

- Declared balances (as in Excel): no verifiable invariant, transfers meaningless.
- One table of transactions with a transfer group id: the transfer invariant is not structural and
  openings/adjustments become special cases everywhere.
- Full double-entry bookkeeping now: too heavy for the UX and queries of personal finance.

## Consequences

- Every movement must be recorded; checkpoints make omissions visible.
- No balance is stored; any future cache must be verifiable against the ledger.
