# Design Decisions

## 1. Keycloak owns authentication policy

Decision: Frontend and Backend do not decide whether Phase 1 or Phase 2 is active.

Reason: The PoC is intended to validate Keycloak/oauth2-proxy capability rather than introduce application-managed authentication orchestration.

Implementation:
- Phase 1 selects `poc-phase1-browser-v2`, which is created by copying built-in `browser`; the built-in flow is never modified.
- Phase 2 selects `poc-phase2-browser-v3`, another independent copy, and enables realm `verifyEmail`. A conditional Trusted Browser subflow is added only to the copied Phase 2 forms flow; untrusted browsers run MFA selector + Email OTP and are trusted automatically for 30 days.
- PowerShell scripts change only Keycloak Admin REST configuration and invalidate realm sessions.

## 2. User account actions use Keycloak Application Initiated Actions

Decision: Verify Email starts `/oauth2/start` with `kc_action=VERIFY_EMAIL`; Verify Email pages may start Keycloak's built-in `UPDATE_EMAIL`; the authenticated application may start `UPDATE_PASSWORD`.

oauth2-proxy explicitly allow-lists only `VERIFY_EMAIL`, `UPDATE_EMAIL`, and `UPDATE_PASSWORD` and forwards those values to Keycloak. This preserves OAuth state/callback handling in oauth2-proxy instead of building authorization URLs or handling credentials in application code. `UPDATE_EMAIL` uses `verifyEmail=true`, while `UPDATE_PASSWORD` reuses Keycloak's registered required action and PATTAYA password-update template. Password values never pass through the PoC frontend/backend.

## 3. Frontend and Backend are separate

Frontend:
- static UI
- no token decoding
- no phase policy

Backend:
- decodes token payload for the PoC
- returns claims to frontend
- does not validate the token by explicit requirement

## 4. Backend is not published directly

Only Kong is the application entry point. Backend uses Docker `expose` rather than a published host port.

This prevents accidentally demonstrating the unvalidated token-decoding endpoint as a directly public API.

## 5. Email OTP uses `skipSetup=true`

Plugin v26.4.3 defaults `skipSetup` to false. This PoC is an administrator-enforced second factor, not an opt-in credential enrollment flow, so the `poc-email-otp` authenticator configuration explicitly enables `skipSetup=true`.

## 6. Phase switch invalidates sessions

Changing realm configuration alone does not retroactively re-run authentication for an existing SSO session. Each phase script therefore calls realm-wide logout after changing the policy.

For local testing, oauth2-proxy's own cookie can also be cleared with Sign out if necessary.

## 7. Phase 2 contract is completion, not UI order

The Phase 2 guarantee is:
- password authentication succeeds,
- Email OTP succeeds,
- email is verified,
- only then is the application session completed.

Keycloak required actions are processed separately from browser-flow authenticators, so the exact order in which OTP and Verify Email screens appear is not treated as a business contract in this PoC.

## 8. Local host ports avoid existing services

Host ports used by this PoC:
- Kong app: 8000
- Kong Admin: 8001
- Keycloak: 18080 -> container 8080
- Mailpit UI: 18025 -> container 8025

The non-default Keycloak/Mailpit host ports avoid collisions with services already running on the development machine. Container-to-container ports remain standard.
