# Architecture — Email 2FA PoC

## Goal

พิสูจน์การใช้งาน Email 2FA โดยให้ Keycloak เป็นผู้ควบคุม authentication flow, oauth2-proxy เป็น OIDC session gateway, Kong เป็น ingress/gateway และ application แยกเป็น Frontend + Backend

## Components

```text
Browser
  |
  v
Kong :8000
  |
  v
oauth2-proxy :4180
  |-----------------------> Keycloak :8080
  |                           |
  |                           v
  |                         Mailpit SMTP :1025
  |
  +--> Frontend (nginx static)
  |
  +--> Backend (Node/Express)
```

## Responsibility split

### Keycloak
- Username/password authentication
- Verify Email required action
- Email OTP authenticator
- OIDC token issuance
- Phase 1 / Phase 2 authentication policy

### oauth2-proxy
- Starts OIDC login
- Stores authenticated browser session
- Handles callback
- Passes access token and user headers upstream
- Allows `kc_action=VERIFY_EMAIL` for Application Initiated Action

### Kong
- Single public entry point for the PoC
- Routes all browser/application traffic to oauth2-proxy

### Frontend
- Shows login identity
- Shows `email_verified`
- Offers Verify Email action
- Shows decoded token payload returned by backend
- Does not enforce authentication phase

### Backend
- Provides `/api/me`
- Decodes JWT payload only
- Does not validate JWT signature, issuer, audience or expiry by design for this PoC
- Does not control Verify Email or Email OTP flow

## Trust boundary

For this PoC, access to Backend is protected by oauth2-proxy session. The backend's decoded token is for display/inspection only and MUST NOT be used as a production authorization decision.

## Request flow

### Normal login
1. Browser calls Kong.
2. Kong forwards to oauth2-proxy.
3. If no session exists, oauth2-proxy redirects to Keycloak.
4. Keycloak executes the active browser flow.
5. Keycloak returns authorization code.
6. oauth2-proxy exchanges code for tokens and creates its session.
7. oauth2-proxy forwards requests to frontend/backend.

### Verify Email button
1. Frontend opens `/oauth2/start?...&kc_action=VERIFY_EMAIL`.
2. oauth2-proxy validates the allowed login parameter and creates OAuth state.
3. oauth2-proxy redirects to Keycloak with `kc_action=VERIFY_EMAIL`.
4. Keycloak executes Verify Email as an Application Initiated Action.
5. Keycloak returns through the normal oauth2-proxy callback.
6. Browser returns to the application.

No application backend endpoint is required to orchestrate this flow.
