# Configuration Guide

## Keycloak

Image: `quay.io/keycloak/keycloak:26.6.2`

Email OTP provider:
`io.github.mesutpiskin:keycloak-2fa-email-authenticator:26.4.3-KC26.6.2`

The provider JAR is added during the Keycloak image build and `kc.sh build` is executed.

Realm: `poc`

Keycloak uses canonical hostname `http://localhost:18080` (`KC_HOSTNAME`) so tokens, userinfo validation, and broker callbacks use one consistent issuer even when server-to-server calls use Docker DNS `keycloak:8080`.

Initial realm state:
- `verifyEmail=false`
- Browser flow = `poc-phase1-browser-v2` by default. Both Phase 1 and Phase 2 flows are created from copies of built-in `browser`; built-in flow remains unchanged.
- Demo user email starts unverified
- SMTP points to Mailpit
- `emailTheme=poc-main` so Verify Email, Email OTP, Update Email confirmation, and Reset Password use the custom PFAS email layout
- `poc-main/email/html/email-verification.ftl` embeds the PFAS logo as a `data:image/png;base64,...` URI generated from the local `template/newlogo.png` reference; no external logo URL is required at delivery time
- `poc-main/email/html/code-email.ftl` and `poc-main/email/text/code-email.ftl` customize the Email OTP message (subject, PFAS layout, embedded logo) using the same `data:image/png;base64,...` logo; the `email-authenticator` (Email OTP) execution/flow itself is unchanged, only its rendered template differs
- `poc-main/email/html/password-reset.ftl` and `poc-main/email/text/password-reset.ftl` customize Reset Password mail with the same PFAS card/Base64-logo treatment and Thai `passwordResetSubject`
- `loginTheme=poc-main` also carries the production PATTAYA login design (from local `template/configmap-pattaya-theme.yaml`): `login.ftl`, `login-update-password.ftl`, and `error.ftl` are the production templates adapted to use the local `newlogo.png` instead of the production's remote asset URLs; `mfa-method-selector.ftl` and `email-code-form.ftl` (the Email OTP code-entry screen) are PoC-specific pages restyled to match the same look, since they are not part of the production ConfigMap
- PATTAYA theme coverage is documented in `docs/pattaya-theme-coverage.md`, with the current shell split documented in `docs/non-login-card-theme.md`: `login.ftl` alone keeps the production two-panel layout, while MFA selector, Email OTP, Change/Reset/forced password, Verify/Update Email, and reachable `keycloak.v2` inherited pages use the centered PFAS card visual family. Shared inherited forms still render through local `poc-main/login/template.ftl` while preserving the Keycloak macro/form contract. The end-user `poc-account` Account Console remains separately branded. This is presentation-only; authentication, MFA, required-action, broker, account-linking, form contracts, and realm behavior are frozen.
- `poc-main/login/messages/messages_en.properties` carries the production ConfigMap's Thai label overrides (username, password, doLogIn, etc.); named `_en` rather than `_th` because the realm has `internationalizationEnabled=false`, so the "en" bundle is always the one Keycloak resolves
- Phase 2 uses `poc-phase2-browser-v3` with a conditional Trusted Browser subflow
- Email OTP executions use `skipSetup=true` so users do not need to enroll an email-OTP credential before admin-enforced 2FA
- Trusted Device Recorder uses `trustDays=30`; trust is created automatically after successful Email OTP and no checkbox is shown
- Reset Credentials uses Keycloak's built-in REQUIRED Reset Password execution; `UPDATE_PASSWORD` must be registered/enabled. It is declared in `poc-realm.json` and `configure-auth-flows.ps1` repairs it idempotently for an existing realm.
- Password expiration is phase-controlled: Phase 1 disables it; Phase 2 sets `forceExpiredPasswordChange(180)`
- In Phase 2, local Keycloak passwords expire after 180 days and users must change them before authentication completes

OIDC client: `poc-app`
- confidential client
- callback: `http://localhost:8000/oauth2/callback`
- web origin: `http://localhost:8000`
- custom `external idp linked` mapper includes `external_idp_linked` in ID, access, userinfo, and introspection tokens; the inclusion flags must be enabled or the mapper is skipped even though the federated identity exists

SMTP:
- host: `mailpit`
- port: `1025`
- TLS: off
- auth: off

## oauth2-proxy

oauth2-proxy is configured with both standard config and Alpha structured config.

Important settings:
- OIDC provider = Keycloak
- `insecureAllowUnverifiedEmail=true` so Phase 1 accepts users with `email_verified=false`
- access token is injected to backend as `Authorization: Bearer ...`
- `/api/` routes to Backend
- `/` routes to Frontend
- `kc_action` is allow-listed only for `VERIFY_EMAIL`, `UPDATE_EMAIL`, and `UPDATE_PASSWORD`; no other Application-Initiated Actions are forwarded
- `clientSecret` is the actual Keycloak client secret `poc-app-secret`
- `skipClaimsFromProfileURL=true` because this PoC does not need group/profile fallback
- `backendLogoutURL` calls the Keycloak OIDC end-session endpoint with `{id_token}` so Sign out clears both oauth2-proxy and Keycloak SSO

The browser-facing authorization URL uses `localhost:18080`, while token/userinfo/JWKS calls use Docker DNS name `keycloak:8080`. The canonical Keycloak hostname keeps the issuer stable across both access paths.

## Kong

Kong runs DB-less with `kong/kong.yml` and exposes:
- proxy: `http://localhost:8000`
- admin: `http://localhost:8001`

The PoC uses a single catch-all service pointing to oauth2-proxy.

Brokered OIDC login can produce several large oauth2-proxy `Set-Cookie` response headers. Kong therefore raises the proxy response buffers in `docker-compose.yml`:
- `KONG_NGINX_PROXY_PROXY_BUFFER_SIZE=64k`
- `KONG_NGINX_PROXY_PROXY_BUFFERS=8 64k`
- `KONG_NGINX_PROXY_PROXY_BUSY_BUFFERS_SIZE=128k`

Without these settings a successful External IdP callback can be converted into HTTP 502 by Kong with `upstream sent too big header while reading response header`.

## Frontend

Static nginx application. It calls `/api/me` and displays:
- username / subject
- email
- `email_verified`
- decoded claims

Verify Email action:

```text
/oauth2/start?rd=http%3A%2F%2Flocalhost%3A8000%2F&kc_action=VERIFY_EMAIL
```

Update Email action:

```text
/oauth2/start?rd=http%3A%2F%2Flocalhost%3A8000%2F&kc_action=UPDATE_EMAIL
```

Change Password action:

```text
/oauth2/start?rd=http%3A%2F%2Flocalhost%3A8000%2F&kc_action=UPDATE_PASSWORD
```

The authenticated frontend sends only the AIA request; password values are entered and submitted directly on Keycloak's PATTAYA `login-update-password.ftl` page. The PoC frontend/backend never receive the new password. The realm registers `UPDATE_EMAIL` with `verifyEmail=true`; its PFAS update-email and status/email templates remain unchanged.

## Backend

Node/Express endpoint:

```text
GET /api/me
```

oauth2-proxy preserves the request path for this upstream, so backend accepts both `/api/me` and `/me` (and the corresponding health aliases) to keep direct/internal checks simple.

The backend performs JWT payload decode only. It deliberately does not verify:
- signature
- issuer
- audience
- expiry
- nonce

This behavior is only for the PoC requirement.
