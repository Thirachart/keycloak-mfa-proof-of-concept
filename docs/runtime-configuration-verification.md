# Runtime Configuration Verification

เอกสารนี้ใช้เป็น checklist สำหรับตรวจสอบว่า runtime configuration ของ PoC ตรงกับ design หลัง start/restart หรือหลังรัน configuration scripts

## Baseline

- Keycloak realm: `poc`
- External IdP realm: `external-idp`
- OIDC client: `poc-app`
- External IdP alias: `lab-idp`
- Application entry point: `http://localhost:8000`
- Keycloak: `http://localhost:18080`
- Mailpit: `http://localhost:18025`
- Built-in Keycloak `browser` และ `first broker login` ต้องไม่ถูกแก้โดย PoC

## Phase 1

Expected runtime configuration:

- `browserFlow=poc-phase1-browser-v2`
- `verifyEmail=false`
- password expiration policy disabled
- Email OTP/MFA not required
- `lab-idp.postBrokerLoginFlowAlias` empty when `require_mfa_after_broker=false`

Expected behavior:

- local user can login with username/password
- user without verified email can login
- user with no email sees `Add email first`; it must not invoke `VERIFY_EMAIL`
- user with an unverified email sees `Verify email`
- verified user sees `VERIFIED`

## Phase 2

Expected runtime configuration:

- `browserFlow=poc-phase2-browser-v3`
- `verifyEmail=true`
- `passwordPolicy=forceExpiredPasswordChange(180)`
- Email OTP required when no valid MFA trust exists

Expected local flow order:

```text
poc-phase2-trusted-mfa                  CONDITIONAL
  PoC Trusted Device Condition          CONDITIONAL
  PoC MFA Method Selector               REQUIRED
  Email OTP                             REQUIRED
  PoC Trusted Device Recorder           REQUIRED
```

## MFA trust

Configuration script:

```powershell
.\scripts\configure-auth-flows.ps1 -TrustedDeviceEnabled $true -TrustDays 30
.\scripts\configure-auth-flows.ps1 -TrustedDeviceEnabled $false -TrustDays 30
```

Expected semantics:

- `TrustedDeviceEnabled=true`: trust is browser/device-specific; claim after skip is `mfa_method=trusted_device`
- `TrustedDeviceEnabled=false`: trust is account-wide; claim after skip is `mfa_method=trusted_account`
- actual OTP authentication emits `mfa_method=email`
- default trust duration is 30 days
- no trust checkbox is displayed
- password/email changes revoke MFA trust
- `scripts/clear-mfa-trust.ps1` must revoke both device and account trust
- realm unmanaged attribute policy must permit admin access to PoC trust attributes so admin revocation works

## External IdP / linked accounts

Expected `lab-idp` configuration:

- enabled
- `firstBrokerLoginFlowAlias=poc-lab-first-login`
- `trustEmail=false`
- `config.showInAccountConsole=ALWAYS`
- `config.require_mfa_after_broker=false` by default

Account Console must report linked-account support enabled when the user is authenticated:

```text
isLinkedAccountsEnabled=true
```

The application link is:

```text
http://localhost:18080/realms/poc/account/account-security/linked-accounts
```

When `require_mfa_after_broker=true`, Phase 2 must bind:

```text
postBrokerLoginFlowAlias=poc-external-idp-post-login-phase2-v2
```

When false, `postBrokerLoginFlowAlias` must be empty.

## oauth2-proxy

Verify:

- OIDC client secret is the actual `poc-app` secret, not a Base64 encoding of it
- browser-facing issuer/auth URLs use canonical Keycloak host `http://localhost:18080`
- `/api/` is routed to backend
- `/` is routed to frontend
- `kc_action` is restricted to the intended `VERIFY_EMAIL`, `UPDATE_EMAIL`, and `UPDATE_PASSWORD` Application-Initiated Actions
- logout performs both oauth2-proxy session logout and Keycloak OIDC end-session logout

## Frontend routes

Verify authenticated application behavior through `http://localhost:8000`, not direct port 18081.

- `/api/me` returns successfully
- direct frontend port redirects to the full application path
- Sign out targets port 8000
- Verify Email targets port 8000
- Change Password targets `/oauth2/start?...&kc_action=UPDATE_PASSWORD` on port 8000
- no-email state targets Keycloak Account Personal Info instead of `VERIFY_EMAIL`
- Manage linked accounts targets Keycloak Account Console

## Backend

`GET /api/me` must work through the proxy path.

For this PoC the backend intentionally only decodes the JWT payload and does not perform signature/issuer/audience/expiry/nonce validation.

## Regression checks discovered during E2E testing

These items previously caused runtime failures and must be checked after configuration changes:

1. oauth2-proxy client secret mismatch -> callback HTTP 500
2. Keycloak internal/external issuer mismatch -> broker/userinfo failure or HTTP 502
3. backend `/api/me` path mismatch -> `Cannot GET /api/me`
4. oauth2-proxy-only logout -> Keycloak SSO immediately logs the user back in
5. unmanaged Keycloak attributes hidden from Admin REST -> MFA trust revocation appears successful but does not revoke
6. IdP missing `showInAccountConsole=ALWAYS` -> Account Console reports `isLinkedAccountsEnabled=false`
7. user without email invoking `VERIFY_EMAIL` -> no useful action; UI must first send user to add an email
8. direct frontend port used for auth actions -> bypasses Kong/oauth2-proxy and can produce incorrect routes

## Required post-change smoke test

After any auth/configuration change, minimally verify:

1. `docker compose config` succeeds
2. all services are running
3. Phase 1 local login succeeds
4. `/api/me` succeeds
5. logout returns to a real login screen and does not silently SSO back in
6. no-email / unverified-email / verified-email UI states are correct
7. Account Console linked-accounts feature is enabled
8. Phase 2 reaches MFA selector and Email OTP
9. selected trust mode skips OTP only according to its configured semantics
10. revoking trust causes OTP to be required again
11. `require_mfa_after_broker=true|false` correctly binds/unbinds post-broker MFA
12. restore the intended runtime phase and lab IdP settings after testing

## Current intended default runtime after testing

- Phase 1
- `TrustedDeviceEnabled=true`
- `TrustDays=30`
- `lab-idp.require_mfa_after_broker=false`
