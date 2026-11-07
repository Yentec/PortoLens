# 0014. Internationalisation

- Status: Accepted
- Date: 2026-11-07

## Decision

- Code, identifiers, comments, tests, commit messages, documentation and domain terms are in
  English.
- The frontend uses i18next with English (default) and French.
- The backend returns stable error `code`s and parameters, never display text; the frontend
  translates them (`errors.<CODE>`).
- Numbers, currencies and dates are formatted with `Intl` according to the user's locale; business
  dates are formatted from `YYYY-MM-DD` strings without a local `Date` (0005).
- Default categories are created in the user's language when the workspace is created and are user
  data afterwards (0006).
