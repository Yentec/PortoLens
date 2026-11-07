# 0013. Authentication and security

- Status: Accepted
- Date: 2026-11-07

## Decision

### Authentication

- **Better Auth**, integrated with a small in-house NestJS layer (mount its handler on
  `/api/auth/*`, `AuthGuard` calling `getSession`). Its "organizations" plugin is not used: the
  workspace is a business concept (0009). Ids are UUIDv7.
- Email + password with mandatory email verification; password rules from NIST 800-63B (12 to 128
  characters, no composition rules, breached passwords rejected); slow hashing with OWASP-compliant
  parameters; identical responses whether an email exists or not.
- TOTP two-factor authentication with backup codes is available in the prototype (optional at
  first); passkeys later.

### Sessions

- Server-side sessions (opaque token, stored hashed), not JWT, for immediate revocation.
- Cookie `__Host-`, `HttpOnly`, `Secure`, `SameSite=Lax`; frontend and API served from the same
  origin (no CORS); `Origin` header checked on every mutating request.
- 7 days sliding, 30 days absolute; a recent authentication (< 10 min) is required for sensitive
  actions (email, password, MFA, export, deletion); active sessions can be listed and revoked; all
  sessions are revoked on password change.

### Guards (in order)

`AuthGuard` (401) → `WorkspaceMemberGuard` (404) → `FeatureGuard` (403, later) → `RoleGuard` (403).
Authentication, authorisation and module activation stay distinct.

### Security baseline

- HTTPS, HSTS, `helmet`, strict CSP; global and auth-specific rate limits.
- Logs carry a `requestId` and never amounts, labels, emails or tokens.
- `security_event` table for authentication events, separate from the business audit log.
- **GDPR**: operation labels may reveal health data (article 9), so the dataset is treated as
  sensitive: EU-headquartered hosting, encryption at rest, encrypted backups with point-in-time
  recovery, minimal and logged staff access, export (JSON/CSV) and full erasure.
- No column-level encryption in the prototype (it would prevent SQL aggregation); to be revisited
  if IBANs or aggregator tokens are ever stored.
- Secrets come from the environment, never from the repository; dependencies are updated
  automatically and audited in CI.
