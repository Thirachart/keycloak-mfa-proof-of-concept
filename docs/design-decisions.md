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

## 9. Remember Me and Forgot Password are hidden on the login page

Decision: `login.ftl` no longer renders the "Remember Me" checkbox or the "Forgot Password" link on the username/password form.

Reason: Requested to be hidden for now (2026-09-03), not a removal of the underlying feature — Keycloak's `realm.rememberMe` / `realm.resetPasswordAllowed` behavior and the `/login-actions/reset-credentials` flow are untouched.

Implementation: The two blocks are wrapped in an FTL comment (`<#-- ... -->`) inside the `form-options-group` div in `keycloak/themes/poc-main/login/login.ftl`, not deleted — remove the comment markers to restore them.

## 10. Theme/ConfigMap must never hardcode an environment URL

Decision: No `.ftl` or `theme.properties` file under `keycloak/themes/poc-main` may hardcode an absolute domain (`localhost:8000`, `pfas-playground.local.pitsdev.com`, a future prod hostname, etc.). Every "return to app" / "start a new AIA flow" link is derived at render time from Keycloak's own request context — in priority order: `pageRedirectUri`, then `actionUri`, then `client.baseUrl` (the Client's **Home URL** field in Keycloak Admin). If none of those have content, the link/button is simply not rendered — there is no hardcoded last-resort domain.

Reason: This ConfigMap is generated once from `keycloak/themes/poc-main` and deployed unchanged to every environment (local docker-compose, the playground test cluster, and eventually prod). An early version of this theme hardcoded `pocAppBaseUrl`/`pocLoginUrl`/`pocUpdateEmailUrl` in `theme.properties`, which meant every environment switch required editing and redeploying the ConfigMap — and briefly caused local testing to redirect to the playground domain by accident. Moving environment identity entirely into Keycloak Admin (`Home URL`, one client setting) means the same generated ConfigMap works everywhere with zero edits.

Implementation: `keycloak/themes/poc-main/login/app-links.ftl` builds oauth2-proxy `/oauth2/start` links from `client.baseUrl` only, returning `""` (not a fallback domain) when it's empty; callers check `(client.baseUrl)?has_content` before rendering. `info.ftl`'s several "กลับไปยังระบบ" buttons follow the same `pageRedirectUri → actionUri → client.baseUrl` chain with no final hardcoded `<#else>`. **Whenever regenerating `deploy/generated/configmap-pattaya-theme.yaml`, verify this still holds** (`grep -rn "http://\|https://" keycloak/themes/poc-main` should show no environment domains) — every environment (including a new prod deployment) only needs its Client's Home URL set once in Keycloak Admin, never a ConfigMap edit.

The non-default Keycloak/Mailpit host ports avoid collisions with services already running on the development machine. Container-to-container ports remain standard.
