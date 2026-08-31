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
- `emailTheme=poc-main` so Verify Email and Email OTP both use the custom PFAS email layout
- `poc-main/email/html/email-verification.ftl` embeds the PFAS logo as a `data:image/png;base64,...` URI generated from the local `template/newlogo.png` reference; no external logo URL is required at delivery time
- `poc-main/email/html/code-email.ftl` and `poc-main/email/text/code-email.ftl` customize the Email OTP message (subject, PFAS layout, embedded logo) using the same `data:image/png;base64,...` logo; the `email-authenticator` (Email OTP) execution/flow itself is unchanged, only its rendered template differs
- Phase 2 uses `poc-phase2-browser-v3` with a conditional Trusted Browser subflow
- Email OTP executions use `skipSetup=true` so users do not need to enroll an email-OTP credential before admin-enforced 2FA
- Trusted Device Recorder uses `trustDays=30`; trust is created automatically after successful Email OTP and no checkbox is shown
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
- `kc_action` is allow-listed for `VERIFY_EMAIL` and `UPDATE_EMAIL`; no other Application-Initiated Actions are forwarded
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

The realm registers `UPDATE_EMAIL` with `verifyEmail=true`. The PFAS login theme overrides `update-email.ftl` and the related `Confirmation email sent` / `Email updated` info screens; the email-update confirmation message also uses the PFAS email theme.

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
