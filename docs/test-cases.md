# Test Cases

## TC-01 Phase 1 local login with unverified email

Precondition: run `scripts/configure-auth-flows.ps1`, `scripts/configure-lab-idp.ps1`, then `scripts/phase1.ps1`.

Expected:

- realm binding is `poc-phase1-browser-v2`
- built-in `browser` flow is unchanged
- `demo / demo1234` can authenticate while `email_verified=false`
- no Email OTP is required
- UI shows email verification state

## TC-02 Verify email from the application

1. Login in Phase 1.
2. Press `Verify email with Keycloak`.
3. Open Mailpit and follow the verification message/link.
4. Return to the application with a fresh login/session.

Expected:

- `email_verified=true`
- event listener records `email_verified_at`
- token contains `email_verified_at`
- UI displays the timestamp

## TC-02A Change email from Verify Email

1. Open a PFAS-themed Verify Email screen and choose `เปลี่ยนอีเมล`.
2. Submit a different email address on the PFAS-themed Update Email form.
3. Confirm that `Confirmation email sent` is rendered inside the PFAS card and references the pending new email.
4. Open the Mailpit email sent to the new address and follow its action-token link.
5. Confirm that `Email updated` is rendered inside the PFAS card and references the new email.

Expected:

- oauth2-proxy forwards `kc_action=UPDATE_EMAIL`
- Keycloak `UPDATE_EMAIL` has `verifyEmail=true`
- PFAS background/card/logo/button styling is present on Update Email and both status screens
- the confirmation message uses the PFAS email theme and Base64 logo
- the account email changes only after the confirmation action-token is completed

## TC-03 Phase 2 local login

Precondition: run `scripts/phase2.ps1` and start a fresh login.

Expected:

- realm binding is `poc-phase2-browser-v3`
- the copied browser forms flow contains conditional subflow `poc-phase2-trusted-mfa`
- `PoC Trusted Device Condition` is `CONDITIONAL`
- MFA selector, Email OTP, and Trusted Device Recorder are `REQUIRED` inside that subflow
- Email OTP execution uses `skipSetup=true`
- email must be verified before authentication can complete
- an untrusted browser must complete Email OTP before oauth2-proxy establishes the application session

## TC-04 External IdP visual distinction

Open the main login page and choose `External Identity Provider Lab`.

Expected:

- main realm uses `poc-main` light/minimal theme
- external realm uses `lab-idp` distinct dark theme
- external login page visibly identifies itself as `External Identity Provider Lab`

## TC-05 First external IdP account link

Use external account `external-demo / external1234`, whose email is also `demo@example.com`.

Expected:

- Keycloak uses independent flow `poc-lab-first-login`
- matching email alone does not silently link because `trustEmail=false`
- user is required to prove ownership of the existing main-realm account according to the copied First Broker Login flow
- after successful linking, Keycloak has a Federated Identity record for alias `lab-idp`
- `external_idp_linked=true` is calculated from that real Federated Identity record
- `external_idp_linked_at` is recorded and returned in the token

## TC-06 External IdP login in Phase 2

Precondition: external account is linked and `scripts/phase2.ps1` is active.

Case A — `require_mfa_after_broker=false`:

- external IdP authenticates the user first
- Keycloak does not bind `poc-external-idp-post-login-phase2-v2`
- no additional Keycloak Email OTP is required after broker login
- application token reports `login_provider=lab-idp`

Case B — `require_mfa_after_broker=true`:

- external IdP authenticates the user first
- Keycloak binds and runs `poc-external-idp-post-login-phase2-v2`
- a trusted browser skips the broker MFA subflow
- an untrusted browser runs the MFA selector and Email OTP after broker login
- application token reports `login_provider=lab-idp`

## TC-07 Phase 2 MFA method selection

Precondition: `scripts/phase2.ps1` is active.

Expected for local login, and for external IdP login only when `require_mfa_after_broker=true`:

- Keycloak shows a dedicated `Choose verification method` page before the OTP challenge
- Email OTP is selected and enabled
- Authenticator App and Passkey/WebAuthn are visible but disabled placeholders
- continuing runs the existing Email OTP authenticator
- the resulting application token contains `mfa_method=email`

## TC-08 Trusted Browser 30 days

Precondition: Phase 2 is active and the user completes Email OTP successfully from a browser that has no valid trust record.

Expected:

- no checkbox or user opt-in is shown
- after successful Email OTP, Keycloak returns an HttpOnly `POC_MFA_TRUST` browser cookie
- the cookie contains an opaque random token, not the server-side record
- user attribute `poc_mfa_trusted_device` stores only a SHA-256 token hash plus expiry/creation timestamps
- the record expiry is 30 days after creation
- the next login from the same browser skips the MFA selector and Email OTP
- the resulting application token contains `mfa_method=trusted_device`
- a different browser without the cookie still requires Email OTP
- an expired or cleared server-side record makes the old cookie invalid

## TC-09 Clear Trusted Browser

Run:

```powershell
.\scripts\clear-mfa-trust.ps1 -Username demo
```

Expected:

- all server-side trusted-device records for `demo` are removed
- existing trust cookies no longer validate
- the next Phase 2 login requires Email OTP again
- changing password or email also clears all trusted-device records

## TC-10 Phase 1 email action state

Expected frontend behavior:

- no email: backend reports `email=null` from the JWT claim source of truth (no proxy-header fallback); UI shows `NO EMAIL` and `Add email first`, linking to Keycloak Account personal info
- email present and unverified: show `NOT VERIFIED` and `Verify email`
- email verified: show `VERIFIED`, show verification timestamp when available, and hide the Verify email action

## TC-11 Password expires after 180 days

Precondition: `scripts/phase2.ps1` is active.

Expected:

- Phase 2 sets `passwordPolicy=forceExpiredPasswordChange(180)`
- a local Keycloak password remains valid for at most 180 days
- after expiry, Keycloak requires `UPDATE_PASSWORD` before completing authentication
- switching back to Phase 1 clears the 180-day password-expiration policy
- the simulated external IdP has its own independent password policy and is not governed by the main realm policy

## TC-12 Unlink external IdP

Precondition: `lab-idp` is configured with `showInAccountConsole=ALWAYS`, and the user has the realm default role (`default-roles-poc`) so the Account Console token contains the built-in `account` roles.

Open `http://localhost:18080/realms/poc/account/account-security/linked-accounts` and unlink `lab-idp` from Keycloak Account Console.

Expected after a fresh token:

- Federated Identity record no longer exists
- `external_idp_linked=false`
- `external_idp_linked_at` is removed by the event listener when the unlink event is observed

## TC-13 Application token handling

Expected:

- oauth2-proxy performs the OIDC login/session role
- backend only base64url-decodes the JWT payload for display
- backend deliberately does not validate signature, issuer, audience, expiry, or nonce in this PoC

## TC-14 Account-wide MFA trust

Precondition: configure Phase 2 with `-TrustedDeviceEnabled $false -MfaTrustDays 30` and clear existing MFA trust for the test user.

Expected:

- the first login from any device runs the MFA selector and Email OTP
- no `POC_MFA_TRUST` browser cookie is required in account-wide mode
- successful OTP stores account trust expiry in `poc_mfa_trusted_until`
- a fresh browser/device with no trusted-device cookie skips selector and OTP until the account trust expires
- the resulting application token contains `mfa_method=trusted_account`
- `clear-mfa-trust.ps1` removes account-wide trust and the next fresh login requires MFA again

## TC-15 Full logout

Expected:

- `/oauth2/sign_out` clears the oauth2-proxy session
- oauth2-proxy invokes the Keycloak OIDC end-session endpoint using the current ID token
- logout redirects to public `/signed-out`, which bypasses oauth2-proxy
- `/signed-out` displays a `Login` button instead of automatically starting authentication
- pressing `Login` starts a fresh oauth2-proxy/Keycloak login and the previous Keycloak SSO session is not silently restored

## TC-16 Require missing email on next login

Precondition: create or select a local user with no email address and run:

```powershell
.\scripts\require-email-verification.ps1 -Username <username>
```

Expected:

- when the signed-in application token has no email, the UI shows both `Add email first` and `Require email on next login`
- `Require email on next login` calls `/api/poc/require-email-verification`, sets `UPDATE_PROFILE + VERIFY_EMAIL` for the current Keycloak user, logs out the Keycloak user session, then signs out oauth2-proxy
- the backend endpoint rejects the presentation action when the current user already has an email
- the admin script remains available as the non-UI way to apply the same required actions
- the script logs out existing sessions unless `-NoLogout` is supplied
- next login stops at Keycloak Update Profile and requires `Email *`
- after submitting the email, authentication continues to Keycloak Verify Email
- Keycloak sends the verification message to the new address
- the user cannot complete authentication until the verification action is completed
- this user-specific flow works even when Phase 1 keeps realm-wide `verifyEmail=false`
