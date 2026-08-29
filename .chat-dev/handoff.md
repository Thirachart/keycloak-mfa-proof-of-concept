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

- `docker compose build keycloak` passes with new custom providers.
- Stack starts successfully.
- `configure-auth-flows.ps1` creates the new Phase 2 and post-broker trusted MFA flows.
- `configure-auth-flows.ps1` was rerun successfully after fixing idempotent subflow detection; no duplicate flow error on rerun.
- Runtime Phase 2 local flow hierarchy verified:
  - `poc-phase2-trusted-mfa` = CONDITIONAL;
  - `PoC Trusted Device Condition` = CONDITIONAL;
  - `PoC MFA Method Selector` = REQUIRED;
  - `Email OTP` = REQUIRED;
  - `PoC Trusted Device Recorder` = REQUIRED.
- MFA trust configs verified through Admin REST in account mode: condition has `trustedDeviceEnabled=false`; recorder has `trustedDeviceEnabled=false` and `trustDays=30`.
- Reconfigured back to default device mode with `TrustedDeviceEnabled=true`, `TrustDays=30` after verification.
- Post-broker flow hierarchy verified with the same condition -> selector -> Email OTP -> recorder sequence.
- Phase 2 runtime binding verified: `browserFlow=poc-phase2-browser-v3` and `passwordPolicy=forceExpiredPasswordChange(180)`.
- External IdP config verified both ways:
  - `require_mfa_after_broker=false` clears post-broker flow;
  - `true` binds `poc-external-idp-post-login-phase2-v2`.
- `clear-mfa-trust.ps1 -Username demo` runs successfully when no trusted records exist.
- Runtime was restored to lab IdP `require_mfa_after_broker=false` and Phase 1 after validation.

## Remaining manual browser checks

- Complete actual email verification link through Mailpit and confirm `email_verified_at` in a fresh token.
- Complete First Broker Login interactively with `external-demo / external1234`, verify account linking, then confirm `external_idp_linked` and `external_idp_linked_at` in a fresh token.
- Run Phase 2 interactively from an untrusted browser and verify selector -> Email OTP -> trusted cookie/server record creation and `mfa_method=email`.
- Login again from the same browser and verify selector/OTP are skipped and token contains `mfa_method=trusted_device`.
- Confirm another browser still requires OTP.
- Clear trust with `clear-mfa-trust.ps1` and confirm the old browser cookie no longer skips OTP.
- Browser-test external IdP with `require_mfa_after_broker=true` for both untrusted and trusted browser paths.
- Browser-test external IdP with `require_mfa_after_broker=false` and confirm no additional Keycloak MFA is shown.
