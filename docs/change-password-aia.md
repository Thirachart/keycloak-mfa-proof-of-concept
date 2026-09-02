# Change Password from Authenticated App — Specification & Plan

## Purpose

Add an explicit **เปลี่ยนรหัสผ่าน** action to the authenticated PoC application so a signed-in user can initiate a password change without using Forgot Password or waiting for the Phase 2 password-expiration policy.

The implementation must delegate credential changes to Keycloak. The application must not accept, validate, store, or submit passwords itself.

## User journey

1. User signs in to the PoC application normally.
2. The authenticated home page shows a **เปลี่ยนรหัสผ่าน** button in the existing action area.
3. The button starts an oauth2-proxy login/AIA round trip with `kc_action=UPDATE_PASSWORD` and return destination `/`.
4. Keycloak renders the existing `poc-main/login/login-update-password.ftl` PATTAYA/PFAS page.
5. User enters a new password and confirmation.
6. Keycloak validates the password against the active realm password policy and updates the credential.
7. On success, the AIA flow returns to the application.
8. When the action was app-initiated, the page shows a **ยกเลิก** action; canceling returns without changing the password.

## Implementation scope

### Frontend

- Add one authenticated-home action link labeled `เปลี่ยนรหัสผ่าน`.
- Use the same oauth2-proxy AIA pattern already used by `UPDATE_EMAIL`:
  - start endpoint: `http://localhost:8000/oauth2/start`
  - return destination: `http://localhost:8000/`
  - Keycloak action: `UPDATE_PASSWORD`
- Do not add password fields or password-handling JavaScript to the frontend.

### Keycloak login theme

- Reuse `keycloak/themes/poc-main/login/login-update-password.ftl`.
- Preserve the existing form contract:
  - form action = `${url.loginAction}`
  - method = POST
  - `password-new`
  - `password-confirm`
  - app-initiated cancel = `cancel-aia=true`
- Keep the PATTAYA/PFAS layout, logo, Sarabun-oriented styling, orange controls, and Thai user-facing labels.
- Do not create a second change-password template unless runtime behavior proves the built-in required-action template cannot serve both forced-expiry and app-initiated flows.

### oauth2-proxy

- Extend the existing `kc_action` allow-list with `UPDATE_PASSWORD`.
- Keep the allow-list explicit; do not forward arbitrary Keycloak actions.
- Existing `VERIFY_EMAIL` and `UPDATE_EMAIL` forwarding behavior remains unchanged.

### Realm / required action

- `UPDATE_PASSWORD` must remain registered and enabled.
- Reuse the existing Keycloak required action; do not create a custom authenticator or backend password endpoint.
- Existing Phase 2 `forceExpiredPasswordChange(180)` policy remains unchanged.

## Out of scope

- Keycloak Admin Console
- custom password storage or validation
- changing the password policy
- changing Phase 1 / Phase 2 authentication flows
- MFA / Email OTP behavior
- Trusted Browser / Trusted Device behavior
- Forgot Password behavior except regression testing
- external IdP password management

## Security / behavior constraints

- Password values must only be submitted to Keycloak.
- The PoC frontend/backend must never receive the new password.
- Existing Keycloak password-policy validation remains authoritative.
- App-initiated cancellation must not update credentials.
- Existing forced-password-change behavior must continue to work with the same template.

## Acceptance criteria

1. After login, the application shows `เปลี่ยนรหัสผ่าน`.
2. The link contains `kc_action=UPDATE_PASSWORD` and returns to `/`.
3. Opening the action while authenticated reaches the PATTAYA change-password page.
4. The page contains `password-new` and `password-confirm` inputs.
5. App-initiated mode renders the `ยกเลิก` button using `cancel-aia=true`.
6. The page does not fall back to stock Keycloak styling.
7. Validation/error messages remain Thai where covered by the local message bundle and are not duplicated.
8. No application endpoint receives password values.
9. Forgot Password / Reset Password and Phase 2 forced-password-expiry still use the existing Keycloak `UPDATE_PASSWORD` required action successfully.
10. No Keycloak Admin Console, MFA, trusted-device, broker, or email-verification behavior changes.

## Test plan

### Static checks

- verify frontend action URL and Thai label
- verify `login-update-password.ftl` retains the required input names and `cancel-aia` contract
- verify `UPDATE_PASSWORD` exists once in `poc-realm.json`
- `git diff --check`

### Runtime smoke checks

- authenticate as the existing demo account without changing its credential
- request the authenticated Change Password AIA URL
- confirm the response renders PATTAYA branding
- confirm `password-new` and `password-confirm` exist
- confirm app-initiated cancel exists
- do not submit a new password during automated smoke testing
- confirm Keycloak logs contain no FreeMarker/template-processing errors

### Manual acceptance

- user clicks `เปลี่ยนรหัสผ่าน` from the authenticated page
- verify visual appearance in browser
- change the password and confirm Keycloak AIA returns through oauth2-proxy to the authenticated frontend
- after successful return, frontend shows `เปลี่ยนรหัสผ่านเรียบร้อยแล้ว` once
- test cancel and confirm no success banner and no credential change
- validation errors remain on the Keycloak card and do not create a false success banner

## Implementation status

Implemented:

- authenticated frontend now exposes `เปลี่ยนรหัสผ่าน`
- action URL uses oauth2-proxy `/oauth2/start` with `kc_action=UPDATE_PASSWORD` and return destination `/`
- oauth2-proxy allow-list now includes only `VERIFY_EMAIL`, `UPDATE_EMAIL`, and `UPDATE_PASSWORD`
- the flow reuses the existing PATTAYA `login-update-password.ftl`; no duplicate password template or backend endpoint was added
- `UPDATE_PASSWORD` remains the same Keycloak required action used by Reset Password and Phase 2 forced-password expiry
- Keycloak AIA success does not render an intermediate `info.ftl` page; Keycloak returns `kc_action=UPDATE_PASSWORD&kc_action_status=success` to oauth2-proxy and oauth2-proxy then redirects to the stored `rd` destination
- because oauth2-proxy consumes the callback query and does not expose `kc_action_status` on the final frontend URL, the app-initiated password page writes a short-lived shared `poc_password_aia_state` cookie only for this AIA: `submitted`, `cancelled`, or `error`
- the authenticated frontend consumes that cookie once; only `submitted` shows the Thai success banner, while cancel/error states are cleared without showing success
- the cookie is host-scoped on localhost and uses `Domain=.pfas.pattaya.go.th` on PFAS production subdomains so `auth.pfas.pattaya.go.th` and `pfas.pattaya.go.th` can share the one-time result

Runtime validation completed:

- oauth2-proxy authorization redirect preserves allow-listed `kc_action=UPDATE_PASSWORD`
- authenticated `demo` session reached the PATTAYA password-update page
- page contained `kc-passwd-update-form`, `password-new`, `password-confirm`, and app-initiated `cancel-aia=true`
- cancel returned to the authenticated application
- existing `demo1234` password still authenticated after cancel, confirming cancellation did not change the credential
- an unlisted example `kc_action=DELETE_ACCOUNT` was stripped from the oauth2-proxy authorization redirect rather than forwarded to Keycloak
- browser/oauth2-proxy logs confirm successful `UPDATE_PASSWORD` AIA callbacks include `kc_action_status=success`, while cancel callbacks include `kc_action_status=cancelled`
- frontend now exposes a one-time password-change success banner driven by the AIA state cookie rather than assuming every return is successful
