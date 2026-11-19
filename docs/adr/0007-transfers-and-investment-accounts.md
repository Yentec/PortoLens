# 0007. Transfers and investment accounts

- Status: Accepted
- Date: 2026-11-07

## Decision

### Transfers

- A `TRANSFER` operation has two entries, each with its own date (a bank transfer can take days).
  Credit date ≥ debit date. The shared operation is the link between both entries.
- A movement to or from an account not tracked in the app (a relative, a professional account) is a
  `TRANSACTION`, not a transfer.

| Transfer                | Classification                     |
| ----------------------- | ---------------------------------- |
| Cash ↔ cash             | Neutral (in transit across months) |
| Cash → investment       | Invested                           |
| Investment → cash       | Disinvested (negative invested)    |
| Investment ↔ investment | Neutral                            |

Transfers count in the month of their cash-side entry.

### Investment accounts

- In the core ledger, an `INVESTMENT` account accepts only `TRANSFER`, `OPENING` and `ADJUSTMENT`.
  Its balance means **net contributions** (deposits − withdrawals), not market value; it can become
  negative when gains are withdrawn.
- Dividends and fees are recorded on the cash account that receives or pays them.
- The future investment module attaches to these accounts through a one-to-one extension table
  (wrapper `PEA`/`CTO`/…, broker) and adds positions, securities operations, FX conversions and
  valuations. Valuation − net contributions = unrealised gain.

### Professional accounts

- Excluded from the prototype. Payments from the freelance company are income on the personal
  account.

## Consequences

- Without the investment module, "Invested" and "Surplus" are still available on the dashboard.
