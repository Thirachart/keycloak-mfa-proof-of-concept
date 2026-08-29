# External IdP Lab

## Purpose

The PoC uses a second Keycloak realm as a self-contained external OpenID Connect identity provider. This avoids requiring Google/Azure credentials while exercising the same broker and account-linking mechanisms that a real external IdP would use.

## Realms and themes

- `poc` — relying realm used by the application. Login theme: `poc-main` (light/minimal).
- `external-idp` — simulated external IdP. Login theme: `lab-idp` (dark/distinct) and visibly labeled `External Identity Provider Lab`.

The visual difference is intentional so browser redirects during broker login are obvious during demonstrations.

## Test identities

Main realm local account:

- username: `demo`
- password: `demo1234`
- email: `demo@example.com`

External IdP account:

- username: `external-demo`
- password: `external1234`
- email: `demo@example.com`
- email verified at external realm: true

Using the same email forces the First Broker Login account-linking path instead of silently demonstrating two unrelated users.

## Broker configuration

Run once after a clean realm import:

```powershell
.\scripts\configure-lab-idp.ps1
```

The script:

1. Copies Keycloak's built-in `first broker login` flow to a new independent flow named `poc-lab-first-login`.
2. Does not modify the built-in flow.
3. Creates/updates OIDC provider alias `lab-idp` in realm `poc`.
4. Uses the external realm's OIDC endpoints.
5. Sets `trustEmail=false`, so matching email alone is not treated as sufficient proof to link accounts.

The external IdP redirect URI is:

`http://localhost:18080/realms/poc/broker/lab-idp/endpoint`

## Linking state returned to the application

`external_idp_linked` is not stored as a duplicate user attribute. A custom Keycloak protocol mapper reads the actual federated identity link for alias `lab-idp` when issuing the token.

`external_idp_linked_at` is stored as a user attribute because Keycloak does not expose a standard linking timestamp for this requirement. The PoC event listener records the timestamp when the federated identity link is created and removes it when the link is removed.

Example claims:

```json
{
  "external_idp_linked": true,
  "external_idp_linked_at": "2026-08-29T09:05:42Z",
  "login_provider": "lab-idp"
}
```

## Phase behavior

Phase 1:

- `poc-phase1-browser-v2` (copy of built-in `browser`; built-in flow remains unchanged)
- email verification optional
- no Email OTP for local login
- no broker post-login Email OTP

Phase 2:

- `poc-phase2-browser-v3` (copy of built-in `browser` plus conditional Trusted Browser MFA subflow in the copied forms flow)
- verified email required before completing login
- local username/password login requires Email OTP only when the browser is not trusted or its 30-day trust has expired
- external IdP MFA is controlled per IdP by `config.require_mfa_after_broker`
- when `true`, Phase 2 binds `poc-external-idp-post-login-phase2-v2` and applies the same Trusted Browser policy after broker authentication
- when `false`, Phase 2 clears the post-broker MFA flow so the external IdP login continues directly to the application

The lab IdP defaults to no additional MFA:

```powershell
.\scripts\configure-lab-idp.ps1 -RequireMfaAfterBroker false
```

To require Keycloak MFA after the lab IdP:

```powershell
.\scripts\configure-lab-idp.ps1 -RequireMfaAfterBroker true
```

Run phase scripts with:

```powershell
.\scripts\phase1.ps1
.\scripts\phase2.ps1
```
