# Session Handoff

## Implemented

- Separated frontend/backend PoC behind Kong and oauth2-proxy.
- Keycloak 26.6.2 with mesutpiskin Email OTP provider.
- Added custom Keycloak extension:
  - `email_verified_at` recorded on successful VERIFY_EMAIL event.
  - `external_idp_linked_at` recorded/removed with federated identity lifecycle.
  - `external_idp_linked` token claim derived from the real Keycloak Federated Identity for alias `lab-idp`.
  - `poc-mfa-method-selector` for explicit MFA method selection.
  - `poc-trusted-device-condition` for 30-day server-side Trusted Browser checks.
  - `poc-trusted-device-recorder` to create Trusted Browser records automatically after successful Email OTP.
- MFA trust model is configurable:
  - `TrustedDeviceEnabled=true`: browser cookie `POC_MFA_TRUST` contains a random opaque token and server stores only `SHA256(token)|expiresAt|createdAt` in `poc_mfa_trusted_device`; trust is per browser/device.
  - `TrustedDeviceEnabled=false`: server stores account-wide expiry in `poc_mfa_trusted_until`; all devices for the same user can skip OTP until expiry.
  - `TrustDays` controls duration and defaults to 30 days.
  - no checkbox/user opt-in is shown; trust is created automatically after successful Email OTP.
  - device mode prunes expired records and retains max 10 active browser records per user.
  - password/email changes clear both device and account-wide trust.
- Added `scripts/clear-mfa-trust.ps1 -Username <user>` for admin/test revocation.
- Added `scripts/require-email-verification.ps1 -Username <user>` for user-specific email enrollment. If email is missing it adds `UPDATE_PROFILE`; while email remains unverified it also adds `VERIFY_EMAIL`, then logs out existing sessions by default so the next login is blocked in Keycloak until the required actions complete.
- Added simulated external OIDC IdP using second Keycloak realm `external-idp`.
- Added distinct themes `poc-main` and `lab-idp`.
- Built-in Keycloak `browser` remains unchanged.
- Phase flows:
  - Phase 1: `poc-phase1-browser-v2`.
  - Phase 2: `poc-phase2-browser-v3`, copied from built-in `browser`, with `poc-phase2-trusted-mfa` CONDITIONAL subflow inside copied forms.
  - Phase 2 trusted MFA order: Trusted Device Condition -> MFA Selector -> Email OTP -> Trusted Device Recorder.
  - Post broker: `poc-external-idp-post-login-phase2-v2` with equivalent conditional trusted MFA subflow.
- External IdP post-broker MFA remains configurable per IdP using `config.require_mfa_after_broker`; lab defaults to `false`.
- `phase2.ps1` binds `poc-external-idp-post-login-phase2-v2` only when that IdP config is `true`.
- Session/token MFA semantics:
  - actual OTP: `mfa_method=email`;
  - valid per-device trust skip: `mfa_method=trusted_device`;
  - valid account-wide trust skip: `mfa_method=trusted_account`.
- Frontend displays separate labels for trusted browser and trusted account sessions.
- Password expiration remains phase-controlled: Phase 1 clears it; Phase 2 enables `forceExpiredPasswordChange(180)` for local `poc` passwords.
- Added/updated docs including `docs/trusted-device-mfa.md`, user journey, test cases, phase switch, external IdP lab, MFA method selection, configuration and design decisions.

## Verified

- `docker compose build keycloak` passes with the custom providers and `docker compose config --quiet` passes.
- All services are running; Kong, Mailpit and PostgreSQL report healthy.
- Full Phase 1 local login was exercised over HTTP through Kong -> oauth2-proxy -> Keycloak -> frontend/backend using `demo / demo1234`; unverified email is accepted and `/api/me` returns a decoded access-token payload.
- oauth2-proxy callback bugs found during E2E were fixed:
  - `clientSecret` now uses the real Keycloak client secret rather than a Base64 string;
  - profile fallback is skipped because the PoC does not require groups/profile lookup;
  - backend supports the `/api/me` path preserved by oauth2-proxy.
- Full logout was exercised with an authenticated session. oauth2-proxy now calls Keycloak OIDC end-session through `backendLogoutURL`; redirecting back shows the Keycloak login form instead of silently restoring the app.
- Verify Email was exercised end-to-end in a fresh Chrome profile: app showed `NOT VERIFIED`, clicking `Verify email` opened the Keycloak AIA confirmation page, submitting it sent `Verify email` to Mailpit, following the actual action-token link returned to the app with `email_verified=true` and a fresh `email_verified_at` timestamp.
- `configure-auth-flows.ps1` is idempotent and now also sets user-profile unmanaged attributes to `ADMIN_EDIT`, allowing server-side MFA trust to be inspected/revoked through Admin REST.
- Phase 2 local flow was exercised over HTTP with a temporary verified test user:
  - credentials -> dedicated MFA selector;
  - selector -> Email OTP page;
  - Mailpit received the 6-digit Email OTP;
  - OTP success returned the application and `/api/me` reported `mfa_method=email`.
- Per-device trust was exercised end-to-end:
  - successful OTP issued HttpOnly `POC_MFA_TRUST`;
  - a new login preserving only the trust cookie skipped selector/OTP;
  - `/api/me` reported `mfa_method=trusted_device`.
- Account-wide trust was exercised end-to-end with `TrustedDeviceEnabled=false`:
  - first device required OTP and did not receive `POC_MFA_TRUST`;
  - a completely fresh second browser/device skipped OTP;
  - `/api/me` reported `mfa_method=trusted_account`.
- `clear-mfa-trust.ps1` originally failed because Keycloak 26 hides unmanaged attributes by default; after `ADMIN_EDIT` was configured it removed account/device trust correctly and the next fresh login returned to the MFA selector.
- Phase 2 runtime binding verified: `browserFlow=poc-phase2-browser-v3`, `verifyEmail=true`, and `passwordPolicy=forceExpiredPasswordChange(180)`.
- External IdP visual path was exercised: main realm shows `External Identity Provider Lab`, redirects to the separate `external-idp` realm, and the external login page uses its distinct theme.
- External broker initially failed with issuer mismatch on userinfo. Keycloak now has canonical `KC_HOSTNAME=http://localhost:18080`; the broker callback proceeds to the independent First Broker Login flow and reaches `Account already exists` ownership verification instead of 502.
- External IdP post-broker config was verified both ways:
  - `require_mfa_after_broker=true` binds `poc-external-idp-post-login-phase2-v2`;
  - `false` clears the post-broker flow.
- Logout UX now redirects to a public `/signed-out` page served directly by Kong/frontend, so oauth2-proxy does not immediately restart authentication. The page shows an explicit `Login` button that starts `/oauth2/start`.
- Verified `/signed-out` returns HTTP 200 without authentication, contains the Login button, and `/oauth2/sign_out?...rd=/signed-out` returns `Location: http://localhost:8000/signed-out`.
- Account Console failures were reproduced in real Chrome. Root causes were an imported `demo` user with no `default-roles-poc` assignment (Account Console API returned 401 because the token lacked `aud=account` / `resource_access.account`) and an obsolete hash URL. Runtime `demo` now has `default-roles-poc`, the clean realm import explicitly assigns it, and the application uses the Keycloak 26 path route `/realms/poc/account/account-security/linked-accounts`.
- `Manage linked accounts` was exercised in a fresh Chrome profile with no 4xx Account Console requests; the page rendered `Linked accounts` and the configured `External Identity Provider Lab` provider.
- Added a minimal `poc-account` Account Console theme derived from `keycloak.v3`; only the Account Console background is overridden to `#eef6ff`. Runtime realm `poc` now uses `accountTheme=poc-account`. Fresh Chrome verified the Linked accounts page loads the custom theme stylesheet and computed body background is `rgb(238, 246, 255)`.
- Missing-email required-action flow was exercised in fresh Chrome with a no-email test user: `UPDATE_PROFILE` stopped login and required `Email *`; after submitting the address, `VERIFY_EMAIL` immediately blocked authentication and Keycloak showed that a verification email had been sent. This works in Phase 1 because both required actions are assigned directly to the user.
- Added presentation UI for the second no-email method: when the current token has no email, the app shows both `Add email first` and `Require email on next login`. The second button calls `/api/poc/require-email-verification`, applies `UPDATE_PROFILE + VERIFY_EMAIL`, logs the Keycloak user out, then signs out oauth2-proxy. Fresh-Chrome E2E confirmed the button, signed-out transition, and next-login `Update Account Information` page. The endpoint is intentionally PoC-only and uses Keycloak admin credentials inside the backend.
- The latest temporary user `button-no-email-test` was disabled after testing; earlier temporary E2E users were deleted.
- Runtime was restored to default device trust (`TrustedDeviceEnabled=true`, 30 days), lab IdP `require_mfa_after_broker=false`, and Phase 1.

- External IdP login now passes end-to-end in a fresh Chrome profile: main realm -> `lab-idp` -> `external-idp` credentials -> broker callback -> application. Kong response buffers were raised because oauth2-proxy's brokered session cookies made the callback response headers exceed the default proxy buffer and caused HTTP 502 (`upstream sent too big header`).
- Runtime and clean realm configuration now enable ID/access/userinfo/introspection inclusion for the custom `external idp linked` protocol mapper. Fresh External IdP login returns `external_idp_linked=true`, `login_provider=lab-idp`, `/api/me` 200, and the UI shows `LINKED`.

## Remaining manual browser checks

- Browser-visual confirmation of the exact rendered appearance remains manual; HTTP E2E verified the pages/forms and flow transitions.
