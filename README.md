# Keycloak MFA Proof of Concept

A self-contained Proof of Concept for Keycloak-controlled authentication with Email OTP MFA, email verification, trusted-device behavior, brokered External IdP login, account linking, Kong, oauth2-proxy, and separated frontend/backend applications.

The PoC is designed to demonstrate authentication behavior primarily through Keycloak configuration and custom providers rather than application-owned authentication logic.

## What this PoC demonstrates

- Phase-based authentication policy controlled by Keycloak
- Email verification with Keycloak Application-Initiated Actions
- Missing-email enrollment with `UPDATE_PROFILE + VERIFY_EMAIL`
- Email OTP MFA using `keycloak-2fa-email-authenticator`
- Explicit MFA-method selection UI, currently exposing Email OTP
- Trusted Browser MFA skip with server-side trusted-device records
- Optional account-wide MFA trust
- Password expiry every 180 days in Phase 2 only
- Brokered login through a simulated External OIDC IdP
- External account linking through Keycloak Federated Identity
- External IdP linked state exposed in tokens
- Custom Account Console branding and navigation
- Kong + oauth2-proxy in front of separated frontend/backend services

## Architecture

```text
Browser
  |
  v
Kong :8000
  |
  v
oauth2-proxy :4180
  |-----------------------> Keycloak realm: poc
  |                            |
  |                            +--> Email verification
  |                            +--> Email OTP / MFA policy
  |                            +--> Account Console
  |                            +--> Broker to lab-idp
  |
  +--> Frontend nginx
  |
  +--> Backend Node/Express

Keycloak realm: external-idp
  +--> acts as the simulated external OIDC Identity Provider

Keycloak
  +--> PostgreSQL
  +--> Mailpit SMTP
```

## Components

- Keycloak `26.6.2`
- `io.github.mesutpiskin:keycloak-2fa-email-authenticator:26.4.3-KC26.6.2`
- Custom Keycloak extension for:
  - `email_verified_at`
  - `external_idp_linked_at`
  - `external_idp_linked`
  - MFA method selector
  - Trusted Browser condition/recorder
- Kong `3.9.3`
- oauth2-proxy `7.14.2`
- PostgreSQL `16-alpine`
- Mailpit `v1.27`
- nginx `1.27-alpine`
- Node.js `22-alpine`

## URLs

- Application through Kong: `http://localhost:8000`
- Kong Admin API: `http://localhost:8001`
- Keycloak: `http://localhost:18080`
- Keycloak Admin Console: `http://localhost:18080/admin`
- Mailpit: `http://localhost:18025`
- Frontend direct: `http://localhost:18081`

## Demo accounts

Keycloak administrator:

```text
admin / admin
```

Main realm local user:

```text
demo / demo1234
```

External IdP user:

```text
external-demo / external1234
```

The clean realm configuration is designed so the local and external demo identities can be used to demonstrate account linking.

## Start from a clean state

```powershell
docker compose down -v
docker compose build
docker compose up -d
.\scripts\configure-auth-flows.ps1
.\scripts\configure-lab-idp.ps1
.\scripts\phase1.ps1
```

Then open:

```text
http://localhost:8000
```

## Authentication phases

### Phase 1

```powershell
.\scripts\phase1.ps1
```

Behavior:

- Uses independent flow `poc-phase1-browser-v2`
- Realm-wide email verification is optional
- Email OTP is disabled
- Password expiration is disabled
- Unverified users may authenticate

### Phase 2

```powershell
.\scripts\phase2.ps1
```

Behavior:

- Uses independent flow `poc-phase2-browser-v3`
- Verified email is required
- Email OTP MFA is required unless a valid trust record exists
- Local Keycloak passwords expire after 180 days
- External IdP post-broker MFA is configurable per IdP

The built-in Keycloak `browser` flow is not modified. The PoC creates and binds independent flows copied from Keycloak-owned flows.

## MFA method selection

Phase 2 contains an explicit MFA method selector.

Currently available:

```text
Email OTP
```

The selector is intentionally separated so additional methods such as TOTP or WebAuthn/Passkeys can be introduced later without redesigning the whole authentication flow.

Email OTP messages also use the custom `poc-main` email theme. The HTML layout follows the PFAS template from the local `template/otp-email.html` reference, including Thai copy, the highlighted OTP code, expiry notice, and PFAS footer. The logo from local `template/newlogo.png` is embedded directly in `code-email.ftl` as a `data:image/png;base64,...` URI, so the delivered email does not depend on an externally hosted logo URL. The plain-text fallback is customized as well. The `email-authenticator` (Email OTP) execution itself is unchanged; only the rendered template differs.

## Trusted Browser / MFA trust

Configuration is controlled by `configure-auth-flows.ps1`.

Default:

```text
TrustedDeviceEnabled=true
TrustDays=30
```

With `TrustedDeviceEnabled=true`:

- successful Email OTP creates a server-side Trusted Browser record
- the browser receives an opaque HttpOnly `POC_MFA_TRUST` cookie
- only a hash of the token is stored server-side
- the same trusted browser can skip OTP until expiry
- token claim `mfa_method=trusted_device`

With `TrustedDeviceEnabled=false`:

- successful OTP creates account-wide trust
- all devices for that account can skip OTP until expiry
- token claim `mfa_method=trusted_account`

Actual Email OTP authentication reports:

```text
mfa_method=email
```

To revoke MFA trust:

```powershell
.\scripts\clear-mfa-trust.ps1 -Username demo
```

## Email verification

The application starts Keycloak's Application-Initiated Action through oauth2-proxy:

```text
/oauth2/start?...&kc_action=VERIFY_EMAIL
```

Keycloak owns the verification process; the application does not implement verification itself.

Verify Email messages use the custom `poc-main` email theme. The HTML layout follows the PFAS template from the local `template/verify-email.html` reference, including Thai copy, the orange verify button, fallback action-token URL, and PFAS footer. The logo from local `template/newlogo.png` is embedded directly in `email-verification.ftl` as a `data:image/png;base64,...` URI, so the delivered email does not depend on an externally hosted logo URL. The plain-text fallback is customized as well.

The browser-side Verify Email flow uses the same PFAS visual language for the Verify Email required-action and action-token screens. Users can choose `เปลี่ยนอีเมล`, which starts Keycloak's `UPDATE_EMAIL` Application-Initiated Action through oauth2-proxy. The update-email form, `Confirmation email sent`, and `Email updated` status screens are themed with the same PFAS card/background/logo styling. `UPDATE_EMAIL` is configured with `verifyEmail=true`, so the new address is not committed until the confirmation link sent to the new mailbox is completed. That confirmation email also uses the PFAS HTML/text theme and Base64 logo.

The realm explicitly sets:

```text
emailTheme=poc-main
```

### User with no email

An administrator can require email enrollment on the next login:

```powershell
.\scripts\require-email-verification.ps1 -Username demo
```

When the user has no email, the script assigns:

```text
UPDATE_PROFILE
VERIFY_EMAIL
```

On the next login Keycloak requires the user to enter an email address and then verify it before authentication can complete.

For presentation, the frontend can also show both approaches when the current user has no email:

- `Add email first`
- `Require email on next login`

The second option uses a PoC-only backend endpoint with Keycloak administrator credentials. It is intentionally not a production security design.

## External Identity Provider lab

The PoC does not depend on Google, Microsoft, or another Internet-hosted IdP.

A second Keycloak realm named `external-idp` acts as the external OIDC provider.

Login path:

```text
Application
  -> poc realm
  -> External Identity Provider Lab
  -> external-idp realm
  -> broker callback
  -> poc user/account linking
  -> Application
```

The External IdP has a visually distinct login theme so broker redirects are obvious during demonstrations.

External IdP post-broker MFA is controlled per IdP with:

```text
config.require_mfa_after_broker=true|false
```

The lab IdP defaults to `false`.

## External account linking

`external_idp_linked` is calculated from Keycloak's actual Federated Identity record rather than duplicated as a user attribute.

The custom mapper exposes the state in ID/access/userinfo/introspection tokens.

A verified External IdP login currently produces values such as:

```json
{
  "external_idp_linked": true,
  "login_provider": "lab-idp"
}
```

If the historical link predates the event listener, `external_idp_linked_at` can legitimately be absent rather than being fabricated.

## Account Console customization

The `poc` realm uses custom Account Console theme:

```text
poc-account
```

It inherits from `keycloak.v3` and explicitly uses:

```properties
darkMode=false
```

Current customizations include:

- Light Account Console
- PoC logo/branding
- blue active navigation
- neutral expanded Account Security navigation
- readable light form controls
- `Device activity` hidden from navigation
- `Applications` hidden from navigation

The routes/features are not deleted; those entries are hidden only from the presentation navigation.

## Kong and large OAuth callback headers

Brokered OIDC sessions can produce several large oauth2-proxy `Set-Cookie` response headers.

Kong is configured with larger proxy response buffers:

```text
KONG_NGINX_PROXY_PROXY_BUFFER_SIZE=64k
KONG_NGINX_PROXY_PROXY_BUFFERS=8 64k
KONG_NGINX_PROXY_PROXY_BUSY_BUFFERS_SIZE=128k
```

Without these settings a successful broker callback can become HTTP `502` with:

```text
upstream sent too big header while reading response header
```

## Backend token handling

The backend intentionally decodes the JWT payload only for this PoC.

It does **not** validate:

- JWT signature
- issuer
- audience
- token expiry
- nonce

This is deliberate for demonstration purposes and must not be copied into production authentication code.

The UI displays relevant state including:

- `email_verified`
- `email_verified_at`
- `external_idp_linked`
- `external_idp_linked_at`
- `login_provider`
- `mfa_method`

## Verified scenarios

The PoC has been exercised end-to-end through the real browser flow for scenarios including:

- Phase 1 local login with unverified email
- Verify Email through Mailpit action-token flow
- Missing-email `UPDATE_PROFILE -> VERIFY_EMAIL`
- Phase 2 Email OTP
- Trusted Browser OTP skip
- Account-wide trust OTP skip
- MFA trust revocation
- Logout through oauth2-proxy + Keycloak
- Account Console Personal Info
- Account Console Linked Accounts
- External IdP login through the simulated OIDC provider
- Brokered callback through Kong/oauth2-proxy
- External linked-account token state

## Useful scripts

```text
scripts/configure-auth-flows.ps1
scripts/configure-lab-idp.ps1
scripts/phase1.ps1
scripts/phase2.ps1
scripts/clear-mfa-trust.ps1
scripts/require-email-verification.ps1
```

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
- `docs/runtime-configuration-verification.md`

## Scope

This repository is a Proof of Concept intended for architecture, authentication-flow, and integration demonstrations. Secrets, HTTP-only local endpoints, administrator credentials, and intentionally relaxed backend token handling are suitable only for the local PoC environment.
