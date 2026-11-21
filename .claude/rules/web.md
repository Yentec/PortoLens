---
paths:
  - 'apps/web/**'
---

# Web app rules (ADR 0012, 0014)

- Server state goes through TanStack Query; API calls use relative URLs (`/api/…`), never an
  absolute origin. Business rules are never re-implemented in the frontend (UX validation only).
- Every visible text is an i18next key present in both `en.json` and `fr.json`; keys are type-checked.
- Business dates are `YYYY-MM-DD` strings formatted without a local `Date`; numbers and currencies
  are formatted with `Intl`.
- Tests: Testing Library queries by role and accessible name; `renderWithProviders` for components
  using queries; mock `fetch` per test with `vi.spyOn`.
- Organise code by feature under `src/features/<feature>/`.
