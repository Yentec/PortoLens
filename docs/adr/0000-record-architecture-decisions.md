# 0000. Record architecture decisions

- Status: Accepted
- Date: 2026-11-07

## Context

The project was designed before any application code was written: scope, ledger model, data model,
modules, API, security and testing. These decisions and their rationale must stay discoverable
next to the code, for future contributors and for our future selves.

## Decision

- Each significant decision is recorded as an ADR in `docs/adr/`, named `NNNN-short-title.md`.
- Sections: Context, Decision, Alternatives considered (when useful), Consequences.
- ADRs are written in English, like the code.
- An accepted ADR is not rewritten. A changed decision gets a new ADR; the old one's status becomes
  `Superseded by NNNN`.
- Identifiers of invariants and edge cases defined in ADRs (`T1`, `O2`, `C14`…) are reused in test
  names, so each rule can be traced to its tests.

## Consequences

- A decision is challenged by writing a new ADR, not by silently changing code.
- Pull requests that change an architectural rule must reference or add an ADR.
