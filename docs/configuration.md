# Configuration Guide

## Keycloak

Image: `quay.io/keycloak/keycloak:26.6.2`

Email OTP provider:
`io.github.mesutpiskin:keycloak-2fa-email-authenticator:26.4.3-KC26.6.2`

The provider JAR is added during the Keycloak image build and `kc.sh build` is executed.

Realm: `poc`

Initial realm state:
- `verifyEmail=false`
- Browser flow = `poc-phase1-browser-v2` by default. Both Phase 1 and Phase 2 flows are created from copies of built-in `browser`; built-in flow remains unchanged.
- Demo user email starts unverified
- SMTP points to Mailpit
- Phase 2 uses `poc-phase2-browser-v3` with a conditional Trusted Browser subflow
- Email OTP executions use `skipSetup=true` so users do not need to enroll an email-OTP credential before admin-enforced 2FA
- Trusted Device Recorder uses `trustDays=30`; trust is created automatically after successful Email OTP and no checkbox is shown
- Password expiration is phase-controlled: Phase 1 disables it; Phase 2 sets `forceExpiredPasswordChange(180)`
- In Phase 2, local Keycloak passwords expire after 180 days and users must change them before authentication completes

OIDC client: `poc-app`
- confidential client
- callback: `http://localhost:8000/oauth2/callback`
- web origin: `http://localhost:8000`

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
- `kc_action` is allowed only for value `VERIFY_EMAIL`

The browser-facing authorization URL uses `localhost:18080`, while token/userinfo/JWKS calls use Docker DNS name `keycloak:8080`.

## Kong

Kong runs DB-less with `kong/kong.yml` and exposes:
- proxy: `http://localhost:8000`
- admin: `http://localhost:8001`

The PoC uses a single catch-all service pointing to oauth2-proxy.

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

## Backend

Node/Express endpoint:

```text
GET /api/me
```

Because oauth2-proxy strips the `/api/` upstream prefix, backend receives `/me`.

The backend performs JWT payload decode only. It deliberately does not verify:
- signature
- issuer
- audience
- expiry
- nonce

This behavior is only for the PoC requirement.
