# 0009. Tenancy and data isolation

- Status: Accepted
- Date: 2026-11-07

## Decision

- **The tenant is the `Workspace`**, not the user. Data belongs to a workspace (`workspace_id` on
  every business table). A `User` authenticates; a `Membership(userId, workspaceId, role)` links
  them. Prototype: one workspace per user, one member with role `OWNER`. Households later add
  members without migrating data.
- Isolation has three independent layers:
  1. **Application**: repositories read `workspaceId` from the request context only, set by the
     membership guard; never from the request body.
  2. **Composite foreign keys** `(workspace_id, id)`: no row can reference another tenant.
  3. **PostgreSQL Row-Level Security**, enabled and forced on every workspace table. Each request
     runs in a transaction that sets `app.workspace_id` and `app.user_id` with
     `set_config(..., true)` (transaction-local). `membership` is filtered by `app.user_id`.
     Authentication tables have no RLS.
- **Database roles**: `app_migrator` (owns the schema, runs migrations), `app_runtime` (DML, no
  `BYPASSRLS`, not table owner, `INSERT`/`SELECT` only on `audit_event`), `app_maintenance` (GDPR
  purge, expiry jobs).
- A resource of another workspace answers **404**, never 403.
- Module activation will be a per-workspace feature table checked by a dedicated guard; billing
  will only feed that table.

## Consequences

- Even a query with a forgotten filter returns no foreign rows.
- Tests must connect as `app_runtime`: a superuser bypasses RLS (0015).
