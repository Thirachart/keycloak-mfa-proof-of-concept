# Email 2FA PoC

PoC stack for Keycloak-controlled authentication with separated frontend/backend, Kong, oauth2-proxy, Email OTP, email verification, account linking, and a self-contained external OIDC IdP lab.

## Components

- Keycloak 26.6.2
- `keycloak-2fa-email-authenticator` 26.4.3-KC26.6.2
- Custom Keycloak extension for verification/link timestamps and external-link token claim
- Kong 3.9.3
- oauth2-proxy 7.14.2
- Frontend served by nginx
- Node.js backend
- PostgreSQL
- Mailpit
- Second Keycloak realm (`external-idp`) used as a simulated external IdP

## URLs

- App through Kong: `http://localhost:8000`
- Kong Admin: `http://localhost:8001`
- Keycloak Admin: `http://localhost:18080/admin`
- Mailpit: `http://localhost:18025`

## Accounts

Keycloak admin: `admin / admin`

Main realm local user: `demo / demo1234`

External IdP user: `external-demo / external1234`

Both demo users use `demo@example.com` intentionally so First Broker Login exercises account linking.

## Start from a clean state

```powershell
docker compose down -v
docker compose build
docker compose up -d
.\scripts\configure-auth-flows.ps1
.\scripts\configure-lab-idp.ps1
.\scripts\phase1.ps1
```

## Phase switch

Phase 1:

```powershell
.\scripts\phase1.ps1
```

Uses the independent `poc-phase1-browser-v2` flow, created by copying Keycloak's built-in `browser` flow. Email verification is optional and Email OTP is disabled.

Phase 2:

```powershell
.\scripts\phase2.ps1
```

Uses the independent `poc-phase2-browser-v3` flow, also created from a Keycloak-owned copy. Verified email is required. MFA trust is configurable with `TrustedDeviceEnabled` and `TrustDays` (default 30). With device mode enabled, trust is per browser; with device mode disabled, successful OTP creates account-wide trust so all devices can skip OTP for the configured period. External IdP post-broker MFA is controlled per IdP by `config.require_mfa_after_broker`; when enabled it uses the same MFA trust policy. The lab IdP defaults to `false`.

No built-in Keycloak Browser flow is modified by the phase switch.

## Password expiry

Password expiration is phase-controlled. Phase 1 disables password expiration. Phase 2 enables `forceExpiredPasswordChange(180)` on the main `poc` realm, so local Keycloak passwords expire after 180 days. When expired, Keycloak requires the user to update the password before authentication can complete. The simulated `external-idp` realm remains independently managed.

## Email verification button

The frontend starts Keycloak's Application-Initiated Action through oauth2-proxy:

`/oauth2/start?...&kc_action=VERIFY_EMAIL`

Keycloak owns the verification flow. The application does not implement it.

## Token state shown by UI

The backend intentionally only decodes the JWT payload for this PoC and performs no signature/issuer/audience/expiry validation.

The UI displays:

- `email_verified`
- `email_verified_at`
- `external_idp_linked`
- `external_idp_linked_at`
- `login_provider`

`external_idp_linked` is calculated from Keycloak's real Federated Identity record, not duplicated as a user attribute.

## Themes

- `poc` realm: `poc-main` light/minimal theme
- `external-idp` realm: `lab-idp` visually distinct dark theme with an `External Identity Provider Lab` label

This makes broker redirects obvious during demonstrations.

## Documentation

- `docs/architecture.md`
- `docs/configuration.md`
- `docs/phase-switch.md`
- `docs/design-decisions.md`
- `docs/runbook.md`
- `docs/test-cases.md`
- `docs/external-idp-lab.md`
- `docs/mfa-method-selection.md`
- `docs/trusted-device-mfa.md`
- `docs/user-journey-by-phase.md`
