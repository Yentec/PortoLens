# 0006. Categories, refunds and fixed charges

- Status: Accepted
- Date: 2026-11-07

## Decision

### Categories

- A category has a kind `INCOME` or `EXPENSE`. **The kind carries the budget meaning; the sign
  carries the cash direction.**
- Names are unique per workspace, case-insensitive. A used category's kind cannot change; a used
  category is archived, never deleted.
- Default categories are created with the workspace, in the user's language, and then become plain
  user data (they are not translated afterwards).

### Line classification

| Line                                | Meaning                        |
| ----------------------------------- | ------------------------------ |
| `INCOME` category                   | Income (negative = correction) |
| `EXPENSE` category, negative amount | Gross expense                  |
| `EXPENSE` category, positive amount | Refund (reduces the expense)   |

### Refunds

- A refund is a separate positive line in an `EXPENSE` category, optionally linked to the refunded
  line by `refundOf`. The original expense stays visible.
- A refund may be partial, full, or split into several lines over several months and accounts.
  Several refund lines may point to the same origin; an origin is never itself a refund.
- A linked refund **has the origin's category**; recategorising the origin propagates to its
  refunds (composite foreign key with `ON UPDATE CASCADE`).
- Status is computed: `NONE`, `PARTIAL`, `FULL`, `EXCEEDED` (no cap: exchange rates can make a
  refund exceed the expense).
- A refund counts in the month of its own date. The dashboard shows **net expenses only**; refunds
  are shown at transaction level.
- Voiding an expense that has linked refunds is rejected; removing a refunded line is rejected.

### Fixed charges

- `isFixed` is a flag on the `TRANSACTION` operation (not on the category: a category mixes fixed
  and variable expenses). Fixed charges are reported net of refunds.

## Consequences

- The workbook's `Remboursement` and `Épargne` categories disappear (refund lines and transfers
  replace them).
