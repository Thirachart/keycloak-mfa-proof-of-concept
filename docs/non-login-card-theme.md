# Non-Login PFAS Card Theme Specification

## Purpose

Keep the production-style two-panel layout only on the primary Login page, while converting every other reachable main-realm browser page that currently uses the Login/two-panel shell to the same centered PFAS card visual language already used by the Update Email page.

The Update Email page is the visual reference for this requirement.

## Visual source of truth

Reference implementation:

- `keycloak/themes/poc-main/login/update-email.ftl`
- `keycloak/themes/poc-main/login/verify-layout.ftl`
- `keycloak/themes/poc-main/login/resources/css/poc.css`

Target visual characteristics:

- warm PFAS page background (`#fff8f2` family)
- centered white card
- PFAS local logo and brand header
- divider between brand and page content
- Thai page title and copy
- PATTAYA orange primary actions
- neutral secondary actions
- consistent field borders/focus/error states
- responsive single-column mobile layout
- PFAS footer / safety note where the shared card layout already provides it

## Scope

### Must remain unchanged

1. `login.ftl`
   - keeps the production two-panel Login layout
   - keeps the production left-panel `login-img.png`
   - keeps existing Login form behavior and styling

2. `update-email.ftl`
   - keeps the current `verify-layout.ftl` PFAS card layout
   - no behavior or form-contract changes

3. Existing Verify Email / Update Email status branches already rendered by `verify-layout.ftl`
   - remain visually unchanged

### Must change from Login/two-panel shell to PFAS card shell

1. `mfa-method-selector.ftl`
   - MFA method selector

2. `email-code-form.ftl`
   - Email OTP entry
   - OTP validation
   - resend
   - cancel

3. `login-update-password.ftl`
   - app-initiated Change Password
   - Reset Password action-token form
   - forced/expired password update

4. `template.ftl`
   - shared shell for reachable Keycloak pages inherited from `keycloak.v2`, including:
     - Forgot Password / reset-credentials request
     - Update Profile / missing-email profile completion
     - First Broker Login review/link pages
     - link-IdP action pages
     - page-expired pages
     - generic inherited browser forms/status pages

### Explicitly out of scope

- `login.ftl` visual redesign
- `update-email.ftl` visual redesign
- Keycloak Admin Console
- `external-idp` / `lab-idp` theme
- Account Console layout
- backend/frontend authentication behavior
- authentication-flow structure
- Email OTP implementation
- Trusted Browser logic
- password policy
- broker/account-linking logic
- `error.ftl` in this requirement, because it does not currently use the two-panel Login shell

## Logic freeze

This requirement is presentation-only.

Do not change:

- form `action`
- HTTP method
- input `name`
- input `value`
- hidden inputs
- submit button `name` / `value`
- `cancel-aia`
- OTP `login`, `resend`, `cancel` submit semantics
- MFA `mfa_method=email`
- FreeMarker conditions controlling authentication behavior
- Keycloak authentication/session scripts in shared `template.ftl`
- required-action conditions
- redirects / action-token behavior
- Phase 1 / Phase 2 bindings

## Implementation plan

1. Reuse `verify-layout.ftl` directly for PoC-owned custom pages where possible:
   - MFA selector
   - Email OTP
   - password update

2. Add reusable card-form styles to `poc.css` for:
   - text/password/OTP controls
   - alert states
   - action stacks
   - MFA option cards
   - password visibility controls

3. Refactor shared `template.ftl` outer shell only:
   - preserve the Keycloak `registrationLayout` macro contract
   - preserve all auth/session scripts and parent-template compatibility behavior
   - replace the two-panel body with PFAS card structure equivalent to `verify-layout.ftl`
   - keep all existing nested sections (`header`, `form`, `info`, `socialProviders`, etc.) and form semantics

4. Do not modify `login.ftl` or `update-email.ftl` unless a regression fix is required to keep them unchanged.

5. Rebuild Keycloak and run runtime checks.

## Acceptance matrix

| Page / flow | Expected shell |
| --- | --- |
| Login | production two-panel Login |
| Login error message inside Login | production two-panel Login |
| Forgot Password | PFAS centered card |
| MFA selector | PFAS centered card |
| Email OTP | PFAS centered card |
| OTP validation / cooldown | PFAS centered card |
| Change Password from app | PFAS centered card |
| Reset Password from email | PFAS centered card |
| Forced/expired password update | PFAS centered card |
| Verify Email | existing PFAS card |
| Update Email | existing PFAS card |
| Update Email confirmation/status | existing PFAS card |
| Update Profile | PFAS centered card |
| Broker review/link pages | PFAS centered card |
| Page Expired | PFAS centered card |
| Generic inherited info/form pages | PFAS centered card |
| Keycloak Admin | unchanged / out of scope |
| lab-idp | unchanged / distinct |

## Runtime validation

Minimum automated/runtime checks:

1. Keycloak image builds successfully.
2. Login still contains `login-container` + two-panel production left image.
3. MFA page contains `poc-verify-card` and no `login-left-panel`.
4. Email OTP page contains `poc-verify-card` and no `login-left-panel`.
5. Password-update page contains `poc-verify-card`, `password-new`, `password-confirm`, and preserves `cancel-aia` in app-initiated mode.
6. Forgot Password inherited page contains `poc-verify-card`, preserves `kc-reset-password-form`, and keeps Thai validation.
7. OTP blank/invalid/cooldown still produces one Thai alert.
8. Shared inherited pages continue to load Keycloak session/auth-check scripts.
9. `update-email.ftl` remains structurally unchanged.
10. `login.ftl` behavior remains unchanged apart from prior committed production-theme work.
11. No FreeMarker/template processing errors appear in Keycloak logs.
12. `git diff --check` passes.

## Manual visual acceptance

Before commit, manually spot-check at least:

- Login (must remain two-panel)
- Forgot Password
- MFA selector
- Email OTP
- Change Password
- Reset Password from email
- Update Email (must remain current card)

The non-login pages should feel like the same component family as Update Email rather than a resized Login page.

## Implementation status

Implemented on 2026-09-01.

Changes applied:

- `login.ftl` remains unchanged and keeps the production two-panel shell.
- `update-email.ftl` and `verify-layout.ftl` remain unchanged and continue to define the PFAS card reference.
- `mfa-method-selector.ftl` now renders through `verify-layout.ftl`.
- `email-code-form.ftl` now renders through `verify-layout.ftl` while preserving `emailCode`, `login`, `resend`, and `cancel` submit semantics.
- `login-update-password.ftl` now renders through `verify-layout.ftl` while preserving `password-new`, `password-confirm`, and `cancel-aia=true`.
- `template.ftl` keeps the Keycloak 26.6.2 `registrationLayout` macro/session/form contract but replaces its two-panel outer shell with the PFAS centered card structure.
- `poc.css` now contains shared card field, alert, action, OTP, and password-visibility styles for non-login pages.
- `pattaya-login.css` remains available for the primary Login page and inherited PatternFly normalization where required; the non-login shell no longer renders `login-left-panel`.

Follow-up visual fix:

- MFA selector radio/text alignment: the shared `.poc-card-form label` rule overrode `.poc-mfa-option { display:flex; }`, causing the OTP option text to fall below the radio. The generic label rule now excludes `.poc-mfa-option`, preserving the horizontal radio + text layout.

Runtime validation completed:

- Keycloak image build/recreate: PASS
- Login two-panel retained: PASS
- Forgot Password card + `kc-reset-password-form` + no left panel: PASS
- MFA selector card + original form contract + no left panel: PASS
- Email OTP card + original form contract + no left panel: PASS
- Reset Password action-token card + `password-new` + `password-confirm` + no left panel: PASS
- temporary smoke-test users cleaned up after runtime checks: PASS
- Login / Update Email / `verify-layout.ftl` unchanged from HEAD: PASS
- shared `template.ftl` auth/session scripts and nested sections preserved: PASS
- form name/value contract checks: PASS
- active realm remains `poc-phase2-browser-v3`, `verifyEmail=true`, `forceExpiredPasswordChange(180)`: PASS
- FreeMarker/template errors in recent Keycloak log: NONE
- `git diff --check`: PASS

Manual pixel-level visual acceptance is still recommended for Login, Forgot Password, MFA selector, Email OTP, Change Password, Reset Password, and Update Email before commit.
