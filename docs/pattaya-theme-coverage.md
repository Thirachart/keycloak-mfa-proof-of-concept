# PATTAYA Theme Coverage & Implementation Status

## Purpose

Extend the production-derived PATTAYA/PFAS visual theme across every **end-user-facing Keycloak browser page that is reachable from this PoC**, while preserving all existing authentication and account behavior exactly as-is.

The theme work is presentation-only by default. One functional configuration defect discovered during manual validation is documented and repaired here as an explicit exception: the main `poc` realm was missing the built-in `UPDATE_PASSWORD` required action even though Reset Credentials contains a REQUIRED Reset Password execution. The document remains the source of truth for scope, bug fixes, implementation status, regression expectations, and future handoff.

## Source of truth for the visual direction

The visual reference is the PATTAYA production login theme imported in commit `3f02046` (`feat: integrate production PATTAYA login theme`) and adapted locally under:

- `template/configmap-pattaya-theme.yaml`
- `keycloak/themes/poc-main/login/resources/css/pattaya-login.css`
- `keycloak/themes/poc-main/login/resources/img/newlogo.png`
- `keycloak/themes/poc-main/login/resources/img/login-img.png` — local copy of the production PFAS left-panel artwork referenced by `template/configmap-pattaya-theme.yaml`; after the non-login card-theme requirement this artwork is intentionally Login-only, while MFA/OTP/password/inherited pages use the Update Email-style PFAS card shell

The following existing pages are already examples of the intended visual language:

- `login.ftl`
- `login-update-password.ftl`
- `mfa-method-selector.ftl`
- `email-code-form.ftl`
- `error.ftl` (production-derived standalone error treatment)

Earlier PFAS-themed Verify Email / Update Email pages remain functionally complete and intentionally keep their existing card-style `verify-layout.ftl` structure. Their visual tokens are harmonized through `poc.css` (PATTAYA orange, focus treatment, and pill-style primary actions) without replacing the proven layout or changing behavior.

## Scope

Theme all user-facing browser pages rendered by the **main `poc` realm** that a user can reach through the flows/configuration present in this repository.

Examples include:

- username/password login
- login validation errors
- MFA method selection
- Email OTP entry, resend, validation errors, and cancellation states
- forced/expired password change
- Verify Email required action and action-token screens
- Update Email form and confirmation/status screens
- missing-email enrollment via `UPDATE_PROFILE`
- Forgot Password / Reset Password flows because `resetPasswordAllowed=true`
- generic user-facing info, success, warning, and error pages
- action-token result/error pages
- main-realm broker/account-linking pages that can be reached from the External IdP journey
- other inherited Keycloak templates only when they are actually reachable from the PoC's current realm settings and flows
- the end-user Keycloak Account Console (`accountTheme=poc-account`) for PATTAYA/PFAS branding/color alignment

## Explicitly out of scope

Do **not** theme or modify:

- Keycloak Admin Console
- Keycloak administration UI of any kind
- `external-idp` realm's intentionally distinct `lab-idp` theme
- frontend application UI unless a separate requirement explicitly requests it
- backend/API behavior
- Mailpit UI
- Kong or oauth2-proxy UI/configuration except where already required by existing behavior

Do not override every Keycloak template indiscriminately. Only add overrides for user-facing pages that are reachable from this PoC.

## Logic freeze / non-negotiable constraints

The implementation must not change authentication, MFA, required-action, broker, or account logic except where a separately confirmed defect is explicitly approved for repair. During manual validation, the user approved one such exception: restoring the missing built-in `UPDATE_PASSWORD` required action needed by Reset Credentials. No browser-flow execution structure was changed for that repair.

The following remain frozen unless a separate requirement explicitly changes them:

- Phase 1 / Phase 2 browser-flow definitions and bindings
- Email OTP authenticator execution
- MFA method-selection behavior
- OTP generation, validation, retry, resend, attempt limits, and cancellation behavior
- Trusted Browser / Trusted Device behavior and persistence
- password-expiration policy and required-action behavior
- `VERIFY_EMAIL`
- `UPDATE_EMAIL`
- `UPDATE_PROFILE`
- External IdP / First Broker Login behavior
- account-linking behavior
- oauth2-proxy OAuth state/callback behavior
- realm configuration and realm feature flags
- form `action` targets
- HTTP methods
- input `name` attributes
- hidden inputs
- submit button `name` / `value` pairs
- FreeMarker conditions that control behavior
- action URLs, redirect URLs, and application-initiated-action URLs

Markup may be reorganized only when the same inputs, actions, conditions, values, and submission semantics are preserved.

## Presentation changes that are allowed

The theme implementation may change:

- page layout
- CSS classes
- typography
- spacing
- colors
- borders and radius
- icons
- logo placement
- responsive behavior
- visual hierarchy
- non-functional wrapper markup
- wording only when it does not change the meaning or behavior of the flow

## Existing implementation inventory

### Already PATTAYA-themed; treat as reference and avoid unnecessary rewrites

| Surface | Template | Status |
| --- | --- | --- |
| Main login | `login.ftl` | PATTAYA production-derived |
| Forced password update | `login-update-password.ftl` | PATTAYA production-derived |
| MFA method selector | `mfa-method-selector.ftl` | PoC-specific, restyled to PATTAYA |
| Email OTP entry | `email-code-form.ftl` | PoC-specific, restyled to PATTAYA |
| Generic error override | `error.ftl` | Production-derived standalone treatment |

### Existing PFAS pages — layout preserved, visual harmonization completed

| Surface | Template | Current state |
| --- | --- | --- |
| Shared Verify/Update shell | `verify-layout.ftl` | Preserved at the previously verified structure; no shared-shell rewrite |
| Verify Email | `login-verify-email.ftl` | Existing PFAS card page preserved |
| Update Email | `update-email.ftl` | Existing PFAS card page preserved |
| Verify/update info states | `info.ftl` | Existing special PFAS card rendering preserved; generic branch uses the shared theme template |

These pages retain their existing actions, conditions, and layout structure. `poc.css` now aligns their primary orange/focus/button treatment with the production-derived PATTAYA visual language.

### Inherited pages covered by the shared PATTAYA template

The main theme has `parent=keycloak.v2`. A local `poc-main/login/template.ftl` now preserves the Keycloak 26.6.2 `registrationLayout` macro contract while replacing the inherited visual shell with the PATTAYA layout. Reachable parent templates that import `template.ftl` therefore keep their built-in form/action logic but render inside the PATTAYA shell.

Coverage includes:

1. **Forgot Password / Reset Password**
   - `poc-realm.json` has `resetPasswordAllowed=true`.
   - The login page exposes `${url.loginResetCredentialsUrl}`.
   - Therefore the reset-credentials journey is in scope.

2. **Update Profile**
   - The PoC deliberately uses `UPDATE_PROFILE + VERIFY_EMAIL` when a user has no email.
   - Any browser page shown by `UPDATE_PROFILE` is in scope.

3. **Generic info/action result pages**
   - `info.ftl` currently falls back to the parent theme for states that are not the explicitly customized Verify/Update Email states.
   - Reachable generic states must use the PATTAYA visual language rather than stock Keycloak styling.

4. **Broker/account-linking pages on the main realm**
   - The External IdP lab uses Keycloak broker flows.
   - Pages rendered by the main `poc` realm during account verification/linking are in scope.
   - Pages rendered by the `external-idp` realm remain intentionally under `lab-idp` and are out of scope.

5. **Action-token errors/results**
   - Invalid, expired, already-used, or completed action links must not drop back to an unthemed Keycloak page when the state is reachable in the PoC.

The reachability inventory confirmed that Keycloak 26.6.2 templates for `login-update-profile.ftl`, `idp-review-user-profile.ftl`, `login-idp-link-confirm.ftl`, `login-idp-link-confirm-override.ftl`, `login-idp-link-email.ftl`, `link-idp-action.ftl`, and `login-page-expired.ftl` import `template.ftl`, so the local shared template covers them without copying their business/form logic. Registration-specific pages remain unnecessary because `registrationAllowed=false` in the main realm.

## Implementation completed

Implemented presentation-only coverage:

- Added `keycloak/themes/poc-main/login/template.ftl` as the shared shell for reachable Keycloak pages that previously inherited the stock `keycloak.v2` shell; the macro/session/form contract remains preserved while the current outer shell is the centered PFAS card used by Update Email.
- `login.ftl` intentionally remains the only production two-panel browser page. `mfa-method-selector.ftl`, `email-code-form.ftl`, and `login-update-password.ftl` now reuse `verify-layout.ftl`, so MFA, Email OTP, Change Password, Reset Password, and forced password changes all use the Update Email-style PFAS card without changing authentication behavior.
- Kept `verify-layout.ftl`, `login-verify-email.ftl`, `update-email.ftl`, and the special Verify/Update branches in `info.ftl` structurally unchanged. Shared card controls were added to `poc.css` so non-login forms use the same fields/buttons/alerts as Update Email.
- Updated `theme.properties` to expose both `poc.css` and `pattaya-login.css` to inherited pages. Existing custom templates that link their stylesheet directly remain unchanged in behavior.
- Extended `pattaya-login.css` with styles for the shared inherited-page shell and inherited Keycloak forms/actions, including normalization for Keycloak v2 `pf-v5-c-form-control` wrappers and vertically stacked primary/secondary action buttons.
- Extended `messages_en.properties` with Thai overrides for reachable reset-password, validation, required-action, broker/linking, expired-session/action-token, and Update Email status messages. The realm intentionally resolves this bundle while internationalization is disabled.
- Aligned the end-user `poc-account` Account Console with PATTAYA orange/background branding and copied the same local `newlogo.png` into its theme resources. No Account Console route or feature logic was changed.
- Keycloak Admin Console, `lab-idp`, application frontend/backend behavior, browser/MFA/broker flow structure, and unrelated realm policy remain outside this implementation. The only functional configuration repair in this work is restoring the missing built-in `UPDATE_PASSWORD` required action required by Keycloak Reset Credentials.

## Validation performed

Automated/runtime checks completed during implementation:

- `docker compose build keycloak` completed successfully.
- Keycloak was recreated from the updated image successfully.
- Main login page still renders the existing PATTAYA login page; invalid credentials produce one Thai alert.
- Forgot Password / Reset Password renders `kc-reset-password-form` inside the new `pattaya-inherited-page` shared shell; title, instructions, and Back to Login are Thai, and blank submission produces one Thai validation message.
- Inherited Reset Password page loads both `poc.css` and `pattaya-login.css` as intended; PatternFly field wrappers/actions are normalized by the local PATTAYA stylesheet.
- Email OTP was exercised through the real Phase 2 flow: blank OTP produces exactly one `กรุณากรอกรหัส OTP` alert and no English `Please specify authenticator code.` message; an invalid OTP also produces exactly one alert with no English authenticator-code marker. Phase 1 was restored after each runtime check.
- Generic Error was exercised by opening a reset-credentials session link without its originating cookie: the primary heading is Thai (`เกิดข้อผิดพลาด`), the session/cookie explanation resolves in Thai, and the original English `Restart login cookie not found` text is not exposed.
- Reachable Thai message overrides were checked for duplicate keys; no duplicate property keys were found and the targeted inherited/reset/profile/broker/action-token message set is covered.
- Keycloak 26.6.2 built-in templates for Update Profile, First Broker Login review/link pages, link-IdP action, and page-expired were verified to import `template.ftl`, so they inherit the local PATTAYA shell without copied flow logic.
- No FreeMarker/template processing error was observed in the Keycloak log during the login/reset smoke checks.
- Reset Password was exercised through the real reset-credentials journey without changing the demo credential: the generated email uses the PFAS HTML template with embedded local Base64 logo and a custom subject, and following the action-token redirect renders the PATTAYA password-update form with both `password-new` and `password-confirm` fields instead of ending at the previous generic `Account updated` state.
- Email OTP resend cooldown was exercised through the real Phase 2 flow: immediate resend produces exactly one Thai `กรุณารอ ... วินาทีก่อนขอรหัสใหม่อีกครั้ง` alert and no English `Please wait ... seconds before requesting a new code.` message.
- Automated user-state mutation for some required-action pages was not used as final acceptance; full browser/manual verification remains appropriate for those flows.

Full browser/manual acceptance is still required before commit for visual appearance and the complete Verify Email, Update Email, missing-email Update Profile, forced-password, broker/account-linking, and Account Console journeys. Runtime regression coverage now includes Login error, Forgot Password validation, Generic Error, blank/invalid Email OTP, OTP resend cooldown, PFAS Reset Password email, and the Reset Password action-token form.

## Bugs found during manual validation

| Bug | Root cause | Fix | Validation |
| --- | --- | --- | --- |
| Forgot Password input looked different from Login, and a follow-up CSS fix briefly removed the idle textbox border entirely | inherited Keycloak v2 markup wraps the input in PatternFly `pf-v5-c-form-control`; the first normalization rule used `border: 0 !important` on the wrapper itself, which overrode the later visible-border rule | limit the border reset to non-`span` form controls; keep the PatternFly wrapper `span` on a persistent `1px #cfd8dc` border with white background and PATTAYA orange `focus-within` ring while still suppressing PatternFly pseudo-underlines | CSS cascade/root cause verified; rebuild/runtime shell check completed; final pixel-level browser spot-check remains manual |
| `Back to Login` showed a blue/PatternFly-looking border | PatternFly button pseudo-elements/focus ring remained active on inherited secondary actions | neutralized PatternFly button pseudo-element borders and replaced focus-visible treatment with the PATTAYA orange focus ring | CSS/image inspection complete; final pixel-level browser spot-check remains manual |
| Blank OTP showed the same error twice | `email-code-form.ftl` rendered both page-level `message.summary` and `messagesPerField.emailCode` | changed OTP rendering to one alert source with field error taking priority | blank OTP = one Thai alert; invalid OTP = one alert |
| OTP validation defaulted to English | reachable Keycloak message keys were not overridden in the resolved `_en` bundle | added Thai overrides such as `missingTotpMessage` and `invalidTotpMessage` | English authenticator-code markers absent in runtime checks |
| OTP resend cooldown showed `Please wait ... seconds...` | plugin key `email-authenticator-resend-cooldown` was not overridden by `poc-main` | added Thai plugin message override | real Phase 2 immediate resend = one Thai cooldown alert, English count 0 |
| Generic Error emphasized English over Thai | `error.ftl` used raw Keycloak summary as the primary heading | made `เกิดข้อผิดพลาด` the primary Thai heading and the sanitized detail secondary; translated reachable session/action-token errors | cookie/session Error runtime check passes in Thai |
| Reset Password email used stock Keycloak mail | `poc-main/email` did not override `password-reset.ftl` or `passwordResetSubject` | added PFAS HTML/plain-text password-reset templates with embedded local Base64 logo and Thai subject | newly generated Reset Password mail is PFAS themed and no longer has default `Reset password` subject |
| Reset Password action link ended at `Account updated` and old password remained valid | `poc-realm.json` explicitly listed required actions but omitted built-in `UPDATE_PASSWORD`; Keycloak logged `Could not find configuration for Required Action UPDATE_PASSWORD` | added `UPDATE_PASSWORD` to `poc-realm.json` and made `configure-auth-flows.ps1` idempotently register/enable it for existing realms | action-token now follows redirect to the PATTAYA password-update form with `password-new` + `password-confirm`; no `Account updated` terminal state before password entry |
| Successful password/account update could end on `อัปเดตบัญชีเรียบร้อยแล้ว` without a clear button | `info.ftl` only had a dedicated CTA for recovery Reset Password; app-initiated password updates and other account-update success states could still fall into the generic Keycloak info branch | keep the recovery-only `เข้าสู่ระบบด้วยรหัสผ่านใหม่` CTA, add an explicit password-update success branch with `กลับไปยังระบบ` (or `ดำเนินการต่อ` when another required action exists), and add a generic account-update success branch with the same PFAS primary CTA behavior | static branch/form-contract validation plus Keycloak rebuild; browser visual spot-check remains manual |

## Visual consistency requirements

All main-realm user-facing pages should clearly belong to the same PATTAYA/PFAS product family.

Use the production-derived theme as the baseline:

- `PATTAYA FINANCIAL AND ACCOUNTING SYSTEM`
- `ระบบการเงินและบัญชีเมืองพัทยา`
- PFAS branding / local `newlogo.png`
- PATTAYA orange visual identity
- Sarabun-oriented typography
- consistent form controls, buttons, focus states, alerts, spacing, and responsive behavior
- Thai as the default user-facing language for reachable validation/status/error messages
- one visible notification for the same validation failure; do not duplicate the same error as both a page-level and field-level alert

Not every page has to copy the two-column login layout literally. Status, success, and error pages may use a simpler centered layout when appropriate, but they must still look like the same application and must not expose stock Keycloak visual styling.

## Asset rule

Prefer local theme assets where practical. The previous theme integration intentionally replaced production-hosted PFAS logo/background URLs with local assets.

If external font/icon CDN references remain, treat removal/self-hosting as a presentation hardening task only; do not let asset cleanup change flow behavior. Any decision to retain or remove external CDN dependencies must be documented during implementation.

## Implementation strategy

1. Inventory all current `poc-main/login` overrides.
2. Map the current realm settings and custom flows to the Keycloak browser templates they can render.
3. Mark each reachable page as:
   - already PATTAYA-themed,
   - existing PFAS page needing visual harmonization,
   - inherited stock Keycloak page needing a new override,
   - intentionally out of scope.
4. Reuse/refactor shared presentation CSS/layout where safe, but do not alter functional FreeMarker conditions or form semantics.
5. Implement missing overrides only for reachable pages.
6. Exercise every affected journey and compare behavior with the pre-theme implementation.
7. Update the inventory/table in this document if implementation discovers additional reachable templates.

## Acceptance criteria

The work is complete when all of the following are true.

### Visual acceptance

No stock Keycloak UI appears during these reachable main-realm journeys:

1. normal username/password login
2. login error
3. Phase 2 MFA method selection
4. Email OTP entry
5. invalid Email OTP
6. Email OTP resend/cancel states
7. forced/expired password change
8. Verify Email
9. resend Verify Email
10. Update Email
11. `Confirmation email sent`
12. `Email updated`
13. missing-email `UPDATE_PROFILE -> VERIFY_EMAIL`
14. Forgot Password / reset-credentials journey
15. generic reachable info/success/warning/error states
16. reachable action-token result/error states
17. main-realm pages used during External IdP account verification/linking

The `external-idp` realm must remain visually distinct under `lab-idp`.

### Behavioral regression acceptance

Theme work must not alter the observable outcome of:

- Phase 1 authentication
- Phase 2 authentication
- Email OTP validation and resend behavior
- Trusted Browser behavior
- email verification
- email update/confirmation behavior
- missing-email enrollment
- password expiration/change
- password reset
- External IdP login and account linking

Existing tests that exercise these behaviors must continue to pass. Theme-specific tests should verify visual/template coverage without redefining authentication logic.

## Handoff rule for future implementers

When implementing this document, do not infer new authentication requirements from visual inconsistencies. If a page looks wrong, fix its template/style only. If making it look correct appears to require changing a flow, authenticator, realm setting, required action, form field contract, or redirect behavior, stop and treat that as a separate requirement rather than changing it as part of this theme task.
