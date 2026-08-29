# Phase Switch Design

## Requirement

The PoC must switch between two authentication policies without changing Frontend or Backend code.

## Phase 1 — Optional email verification

Policy:
- username/password login is enough
- user may have `email_verified=false`
- Email OTP is not required
- UI must show verification status
- user can explicitly start Verify Email from the UI

Keycloak state:
- `verifyEmail=false`
- `browserFlow=poc-phase1-browser-v2`

Activate:

```powershell
./scripts/phase1.ps1
```

The script also runs realm-wide logout so an existing SSO session cannot hide the policy change during testing.

## Phase 2 — Verified email + Trusted Browser + Email OTP

Policy:
- email must be verified
- username/password authentication checks a server-side Trusted Browser record before MFA
- an untrusted/expired browser is followed by MFA selector + Email OTP and is then trusted automatically for 30 days
- a valid trusted browser skips Email OTP
- unverified users are forced through Keycloak Verify Email required action before completing login

Keycloak state:
- `verifyEmail=true`
- `browserFlow=poc-phase2-browser-v3`

Activate:

```powershell
./scripts/phase2.ps1
```

The custom browser flow contains:
1. Cookie authenticator
2. Identity Provider Redirector
3. Username/password form
4. Conditional trusted-device MFA subflow: trusted-device condition → MFA selector → Email OTP → trusted-device recorder

The switch is made through Keycloak Admin REST only. Frontend and Backend are unchanged.

## Why this approach

Using separate Keycloak flows avoids application-controlled authentication logic. It also makes the migration policy observable and reversible during a PoC.

A production rollout can later replace the local PowerShell scripts with infrastructure automation or controlled Keycloak Admin API deployment, while preserving the same concept.

## Expected test behavior

### Switching Phase 1 -> Phase 2

1. Run `phase2.ps1`.
2. Existing realm sessions are invalidated.
3. Next request redirects to Keycloak.
4. If email is unverified, Keycloak requires verification.
5. User then completes Email OTP.
6. oauth2-proxy creates a new authenticated session.

### Switching Phase 2 -> Phase 1

1. Run `phase1.ps1`.
2. Existing sessions are invalidated.
3. Next login requires username/password only.
4. `email_verified=false` is accepted by oauth2-proxy.
5. UI still exposes Verify Email as an explicit action.
