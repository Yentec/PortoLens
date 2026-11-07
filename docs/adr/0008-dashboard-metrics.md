# 0008. Dashboard metrics

- Status: Accepted
- Date: 2026-11-07

## Decision

Cash basis: an element counts in the month of its entry date. Voided operations are excluded.

| Metric        | Formula for month M                                                |
| ------------- | ------------------------------------------------------------------ |
| Income        | Σ signed `INCOME` lines                                            |
| Expenses      | −Σ `EXPENSE` lines (net of refunds)                                |
| Fixed charges | −Σ `EXPENSE` lines of fixed transactions                           |
| Savings       | Income − Expenses                                                  |
| Savings rate  | Savings / Income; `null` when Income ≤ 0                           |
| Invested      | Net cash outflow of transfers between cash and investment accounts |
| Surplus       | Savings − Invested                                                 |
| By category   | Net amount per category                                            |

Control identity (tested on every month, edge case C14):

`Δ cash = Savings − Invested + Openings + Adjustments + InTransit`

where InTransit is the cash-side sum of cash ↔ cash transfers in M (non-zero when debit and credit
fall in different months).

### Averages

- Computed over the **12 most recent complete months** (fewer if the history is shorter); the
  current month is shown as in progress and excluded. The number of months used is displayed.
- Every complete month counts, including months with zero or negative savings (the workbook's
  `AVERAGEIF(">0")` excluded them and biased averages upward).
- Liquidity months = current cash / average expenses; safety fund N months = N × average expenses
  (N = 1, 6, 12). Undefined ratios are `null`.

### Precision

- Computed on exact decimals; rounded for display only.

## Consequences

- There is no "refunds" indicator on the dashboard.
- Metrics are computed in SQL by the reporting module (0011), never stored.
